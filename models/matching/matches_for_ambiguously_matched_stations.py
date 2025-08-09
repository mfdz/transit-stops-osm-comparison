import pandas as pd
import typing as t
from sqlmesh import ExecutionContext, model
from datetime import datetime
import logging
import math
import duckdb

RATING_BELOW_CANDIDATES_ARE_IGNORED = 0.04
MAX_CANDIDATE_COUNT_PER_STOP_BEFORE_ONLY_BEST_PER_QUAY_ARE_CONSIDERED=50

def get_total_rating_sum(matches, agency_stops_cnt):
    # All agency stops are matched, calculated rating for this match assembly
    unmatched_cnt = agency_stops_cnt - len(matches)
    # Rank all unmatched with the mininum acceptance value
    rating_of_unmatched_stops = RATING_BELOW_CANDIDATES_ARE_IGNORED * unmatched_cnt
    summed_ratings_of_matched_stops = math.fsum(map(lambda m: m['similarity'], matches))
    return (rating_of_unmatched_stops + summed_ratings_of_matched_stops) / agency_stops_cnt

def best_unique_matches(candidates_per_ifopt, matches = [], matched_index = 0, already_matched_osm = []):
    # This function recursively tries to figure out the best matches.
    # It is a brute force algorithm with O(n!) to solve this https://en.wikipedia.org/wiki/Assignment_problem. 
    # Instead, e.g. https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html
    # could be used to speed up this calculation
    # Params:
    # - candidates: a map with stop_ids as keys and a list of possible match candidates. The list is assumed to be sorted by descending similarity, then osm_id
    # - agency_stops: an array of stop_ids of already assigned
    # - match_index: number of already matched stops
    # - already_matched_osm: a list of already matched osm ids
    if matched_index == 0:
        # On first call, initialise 
        # 1) a set containing all official quays to match,
        # 2) a map storing all possible candidates per 
        #
        # If the number of candidate pairs exceeds MAX_CANDIDATE_COUNT_PER_STOP_BEFORE_ONLY_BEST_PER_QUAY_ARE_CONSIDERED,
        # Only the best candidates for every stop are retained for further match picking. 
        cand_count = sum([len(candidates_per_ifopt[ifopt]) for ifopt in candidates_per_ifopt])
        
        if cand_count > MAX_CANDIDATE_COUNT_PER_STOP_BEFORE_ONLY_BEST_PER_QUAY_ARE_CONSIDERED:
            for ifopt in candidates_per_ifopt:
                # retain only best candidate to reduce complexity
                candidates_per_ifopt[ifopt] = [candidates_per_ifopt[ifopt][0]]
    
    agency_stops_cnt = len(candidates_per_ifopt)
             
    if matched_index < agency_stops_cnt:
        ifopt = list(candidates_per_ifopt.keys())[matched_index]
        stop_candidates = candidates_per_ifopt[ifopt]
        
        (best_rating, best_matches) = best_unique_matches(candidates_per_ifopt, matches.copy(), matched_index+1, already_matched_osm)
        for candidate in stop_candidates:
            candidate_id = candidate["osm_id"]
            # We allow multiple osm features to match for identity matches
            if not candidate_id in already_matched_osm or candidate["similarity"]==1.0:
                (rating, current_matches) = best_unique_matches(candidates_per_ifopt, matches.copy()+[candidate], matched_index+1, already_matched_osm+[candidate_id])
                if rating > best_rating:
                    best_rating = rating
                    best_matches = current_matches
            if candidate["similarity"]==1.0:
                # In case we saw a best match, we won't search further
                # (Might need to revise if we want to return multiple osm stops for one ifopt, 
                # e.g. because only stations (and no quays) is known)
                break
            
        return (best_rating, best_matches)
    else:
        return (get_total_rating_sum(matches, agency_stops_cnt), matches)


def match(rows: pd.DataFrame) -> pd.DataFrame:
    matchsets = []
    idx = 0
    ifopt_id_col = 0
    matchset_count = 0

    while idx < len(rows):

        first = True
        subset_size = 0
        matchset_count += 1
        candidates = {}
        new_rows = []
        time_start = datetime.now()
        # Collect all matches for same parent stop (assuming their stop_id have same leading <country>:<district>:<parentid> )
        while idx < len(rows) and (first or rows.iloc[idx]['parent_or_station'] == rows.iloc[idx-1]['parent_or_station']):
        
            new_rows.append(rows.iloc[idx])    
            ifopt_id = rows.iloc[idx]["globaleid"]

            if not ifopt_id in candidates:
                candidates[ifopt_id] = []
            candidates[ifopt_id].append(rows.iloc[idx])

            # Collect all matches for same parent stop (assuming their stop_id have same leading <country>:<district>:<parentid> )
            subset_size += 1
            idx += 1
            first = False    
        collected_time = datetime.now()
        
        if subset_size < 30:
            # pick best matches
            (rating, matches) = best_unique_matches(candidates)
            matchsets.extend(matches)
        else:
            # pick best matches per area. Note that this may result in
            # duplicated osm_id assignments in different areas, which
            # need to be post processed and may result in unmatched platforms...
            bereiche = {}
            for ifopt_id in candidates:
                bereich_id = ifopt_id[:ifopt_id.rindex(':')]
                if not bereich_id in bereiche:
                    bereiche[bereich_id] = {}
                bereiche[bereich_id][ifopt_id] = candidates[ifopt_id]
            for bereich_id in bereiche:
                (rating, matches) = best_unique_matches(bereiche[bereich_id])
                matchsets.extend(matches)
        matched_time = datetime.now()
        if ((matched_time-time_start).total_seconds()>3):
            print(rows.iloc[idx-1]["parent_or_station"], matched_time-time_start)
        
        if matchset_count % 5000 == 0:
            yield pd.DataFrame(matchsets, columns=['parent_or_station','globaleid','osm_id','similarity'])
            matchsets = []
            print(f'Matched {matchset_count}...')
    yield pd.DataFrame(matchsets, columns=['parent_or_station','globaleid','osm_id','similarity'])
    print(f'Matched {matchset_count}.')


def test_match(ifopt_prefix = ''):
    con = duckdb.connect('db.db', read_only=True)
    con.load_extension("spatial")
    rows = con.sql(f"SELECT parent_or_station, globaleid, osm_id, similarity FROM matching.ranked_match_candidates WHERE parent_or_station LIKE '{ifopt_prefix}' AND parent_or_station IN (SELECT * FROM matching.ambiguously_matched_stations) and stop_ranking < 5 ORDER BY parent_or_station,globaleid,similarity DESC, osm_id").df()
    for matches in match(rows):
        yield (matches)

@model(
    "matching.matches_for_ambiguously_matched_stations",
    columns={
        "parent_or_station": "text",
        "globaleid": "text",
        "osm_id": "text",
        "similarity": "double",
    },
    cron='@weekly',
    kind="FULL"
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    logger = logging.getLogger(__name__)

    ambiguously_matched_stations_table = context.resolve_table("matching.ambiguously_matched_stations")
    match_candidates_table = context.resolve_table("matching.ranked_match_candidates")

    debug = False
    query = f"SELECT parent_or_station, globaleid, osm_id, similarity FROM {match_candidates_table} WHERE parent_or_station IN (SELECT * FROM {ambiguously_matched_stations_table}) ORDER BY parent_or_station,globaleid,similarity DESC,osm_id {'LIMIT 0' if debug else ''}"
    
    rows = context.fetchdf(query)

    if len(rows) == 0:
        yield from () 
        return 

    for matches in match(rows):
        yield (matches)

if __name__ == '__main__':
    for matches in test_match():
        print(matches)