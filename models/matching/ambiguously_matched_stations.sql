MODEL (
  name matching.ambiguously_matched_stations,
  kind FULL
);

WITH best_match_candidates AS (
  SELECT
    parent_or_station,
    globaleid,
    osm_id
  FROM matching.ranked_match_candidates AS c
  WHERE
    stop_ranking = 1
), osm_stops_being_best_stop_for_multiple_quays AS (
  SELECT
    osm_id,
    parent_or_station,
    COUNT(*) AS cnt
  FROM best_match_candidates
  GROUP BY
    parent_or_station,
    osm_id
  HAVING
    cnt > 1
)
SELECT DISTINCT
  parent_or_station
FROM osm_stops_being_best_stop_for_multiple_quays