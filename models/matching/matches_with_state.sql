MODEL (
  name matching.matches_with_state,
  kind VIEW
);

WITH stations_with_at_least_on_match AS (
  SELECT DISTINCT
    parent_or_station AS station
  FROM matching.matches
), multiple_osm_matches_for_ifopt AS (
  SELECT
    stop_id
  FROM matching.matches
  GROUP BY
    stop_id
  HAVING
    COUNT(*) > 1
)
SELECT
  t.*,
  o.osm_id,
  CASE
    WHEN m.stop_id IS NULL AND t.route_short_names IS NULL
    THEN 'NO_MATCH_AND_SEEMS_UNSERVED'
    WHEN m.stop_id IS NULL AND NOT l.station IS NULL
    THEN 'NO_MATCH_BUT_OTHER_PLATFORM_MATCHED'
    WHEN m.stop_id IS NULL
    THEN 'NO_MATCH'
    WHEN NOT a.stop_id IS NULL
    THEN 'MATCHED_AMBIGUOUSLY'
    WHEN r.similarity_successors = -1.0
    THEN 'MATCHED_THOUGH_REVERSED_DIR'
    WHEN r.distance > 200
    THEN 'MATCHED_THOUGH_DISTANT'
    WHEN o.empty_name = 1
    THEN 'MATCHED_THOUGH_OSM_NO_NAME'
    WHEN r.similarity_jaccard < 0.4
    THEN 'MATCHED_THOUGH_NAMES_DIFFER'
    ELSE 'MATCHED'
  END AS MATCH_STATE,
  r.*
  EXCLUDE (stop_id, osm_id)
FROM matching.transit_stops AS t
LEFT JOIN matching.matches AS m
  ON t.stop_id = m.stop_id
LEFT JOIN matching.rating_similarity_all AS r
  ON m.stop_id = r.stop_id AND m.osm_id = r.osm_id
LEFT JOIN stage.osm_stops AS o
  ON o.osm_id = m.osm_id
LEFT JOIN (
  SELECT
    station
  FROM stations_with_at_least_on_match
) AS l
  ON t.parent = l.station
LEFT JOIN (
  SELECT
    stop_id
  FROM multiple_osm_matches_for_ifopt
) AS a
  ON m.stop_id = a.stop_id