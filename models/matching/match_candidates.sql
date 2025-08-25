MODEL (
  name matching.match_candidates,
  kind FULL,
  description "",
  audits (
    transit_osm_candidate_pairs_unique
  )
);

WITH filtered_match_candidates AS (
  SELECT mv.* FROM matching.match_candidates_in_vicinity mv
    JOIN stage.osm_stops o USING (osm_id)
    JOIN matching.transit_stops t USING (globaleid)
WHERE NOT ifnull((o.mode in ('trainish', 'train','light_rail','tram', 'ferry') AND t.mode IN ('bus'))
OR (o.mode in ('bus') AND t.mode IN ('tram', 'light_rail', 'train', 'trainish', 'ferry')), false)
OR o.ref=t.globaleid ) ,
distance_ranked_match_candidates AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY globaleId ORDER BY distance ASC) AS stop_ranking
  FROM filtered_match_candidates
)
SELECT
  *
FROM distance_ranked_match_candidates
WHERE
  stop_ranking <= LEAST(number_of_station_quays + 5, @MAX_NUMBER_OF_CANDIDATES_PER_QUAY)