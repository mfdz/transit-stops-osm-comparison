import pandas as pd
import typing as t
from scipy.optimize import linear_sum_assignment
from sqlmesh import ExecutionContext, model
from datetime import datetime
import logging
import math
import duckdb

def match(rows: pd.DataFrame) -> pd.DataFrame:
    from scipy.optimize import linear_sum_assignment

    all_matches = []
    for station_id in rows['parent_or_station'].unique():
        # Build pivot by ifopt and osm_id
        candidates_per_parent = rows.loc[rows['parent_or_station'] == station_id]
        similarity_matrix = candidates_per_parent.pivot(columns='stop_id', index='osm_id',values='similarity').fillna(0.0)
        # solve assignment problem
        x,y = linear_sum_assignment(similarity_matrix)
        # collect results
        matches = pd.DataFrame({'stop_id': similarity_matrix.columns[y], 'osm_id': similarity_matrix.index[x]})
        # return df
        all_matches.append(matches)
        
    return pd.concat(all_matches)

@model(
    "matching.matches_for_ambiguously_matched_stations",
    columns={
        "stop_id": "text",
        "osm_id": "text",
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

    match_candidates_table = context.resolve_table("matching.imperfect_match_candidates")
    districts_df = context.fetchdf("SELECT DISTINCT substr(parent_or_station,0,9) district FROM matching.imperfect_match_candidates ORDER BY substr(parent_or_station,0,9)")
    idx = 0
    while idx < len(districts_df):
        district = districts_df.iloc[idx]['district']
        # linear_sum_assignment optimizes for least sum, so we need to inverse similarity
        query = f"SELECT parent_or_station, stop_id, osm_id, -similarity similarity FROM {match_candidates_table} WHERE parent_or_station LIKE '{district}%' ORDER BY parent_or_station,stop_id,similarity DESC, osm_id"
        rows = context.fetchdf(query)
        
        if not len(rows) == 0:
            result = match(rows)
            yield result
        idx += 1
