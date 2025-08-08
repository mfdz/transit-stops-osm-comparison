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
    globaleid
  FROM matching.matches
  GROUP BY
    globaleid
  HAVING
    COUNT(*) > 1
)
SELECT
  t.*,
  CASE
    WHEN m.globaleid IS NULL AND t.route_short_names IS NULL
    THEN 'NO_MATCH_AND_SEEMS_UNSERVED'
    WHEN m.globaleid IS NULL AND NOT l.station IS NULL
    THEN 'NO_MATCH_BUT_OTHER_PLATFORM_MATCHED'
    WHEN m.globaleid IS NULL
    THEN 'NO_MATCH'
    WHEN NOT a.globaleid IS NULL
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
  END AS MATCH_STATE
FROM matching.transit_stops AS t
LEFT JOIN matching.matches AS m
  ON t.globaleid = m.globaleid
LEFT JOIN matching.rating_similarity_all AS r
  ON m.globaleid = r.globaleid AND m.osm_id = r.osm_id
LEFT JOIN stage.osm_stops AS o
  ON o.osm_id = m.osm_id
LEFT JOIN (
  SELECT
    station
  FROM stations_with_at_least_on_match
) AS l
  ON m.parent_or_station = l.station
LEFT JOIN (
  SELECT
    globaleid
  FROM multiple_osm_matches_for_ifopt
) AS a
  ON m.globaleid = a.globaleid