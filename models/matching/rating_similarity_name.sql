MODEL (
  name matching.rating_similarity_name,
  kind FULL
);

WITH names AS (
  SELECT
    c.globaleid,
    o.osm_id,
    REPLACE(t.stop_long_name, ',', '') AS stop_long_name,
    t.locality,
    t.stop_name_without_locality,
    REPLACE(o.name, ',', '') AS osm_name
  FROM matching.match_candidates AS c
  JOIN matching.transit_stops AS t
    USING (globaleid)
  JOIN stage.osm_stops AS o
    USING (osm_ID)
)
SELECT
  CASE
    WHEN osm_name IS NULL
    THEN @NAME_SIMILARITY_OSM_NAME_EMPTY
    ELSE GREATEST(JACCARD(stop_long_name, osm_name), JACCARD(stop_name_without_locality, osm_name))
  END AS similarity_jaccard,
  globaleid,
  osm_id,
  stop_long_name,
  stop_name_without_locality,
  osm_name
FROM names