MODEL (
  name matching.match_candidates,
  kind FULL,
  description "",
  audits (
    transit_osm_candidate_pairs_unique
  )
);

WITH distance_ranked_match_candidates AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY globaleId ORDER BY distance ASC) AS stop_ranking
  FROM matching.match_candidates_in_vicinity
)
SELECT
  *
FROM distance_ranked_match_candidates
WHERE
  stop_ranking <= LEAST(number_of_station_quays + 5, 15)