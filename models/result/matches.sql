MODEL (
  name result.matches,
  kind FULL
);

SELECT
  stop_long_name,
  locality,
  stop_name_without_locality,
  t.stop_id AS stop_id,
  t.parent,
  t.latitude,
  t.longitude,
  t.mode,
  t.match_state,
  o.osm_id,
  ROUND(r.distance, 1) AS distance,
  ROUND(r.similarity, 2) AS rating,
  o.name AS "osm_name",
  route_short_names AS "routes",
  official_direction,
  osm_direction,
  CASE
    WHEN o.osm_id IS NULL
    THEN 'POINT(' || t.longitude || ' ' || t.latitude || ')'
    ELSE 'LINESTRING(' || t.longitude || ' ' || t.latitude || ',' || o.lon || ' ' || o.lat || ')'
  END AS WKT
FROM matching.MATCHES_with_state AS t
LEFT JOIN matching.rating_similarity_all AS r
  USING (stop_id, osm_id)
LEFT JOIN stage.osm_stops AS o
  ON o.osm_id = t.osm_id
LEFT JOIN (
  SELECT
    osm_id,
    LISTAGG(successor_name, ' / ') AS osm_direction
  FROM stage.osm_stops_successor_name
  GROUP BY
    osm_id
) AS osm_succ
  ON o.osm_id = osm_succ.osm_id
LEFT JOIN (
  SELECT
    stop_id,
    LISTAGG(long_successor_name, ' / ') AS official_direction
  FROM stage.gtfs_stops_successor_names AS g
  GROUP BY
    g.stop_id
) AS gtfs_succ
  ON t.stop_id = gtfs_succ.stop_id