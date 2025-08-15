MODEL (
  name matching.rating_similarity_mode,
  kind FULL
);

WITH names AS (
  SELECT
    c.globaleid,
    o.osm_id,
    t.mode AS mode_transit,
    o.mode AS mode_osm
  FROM matching.match_candidates AS c
  JOIN matching.transit_stops AS t
    USING (globaleid)
  JOIN stage.osm_stops AS o
    USING (osm_ID)
)
SELECT
  CASE
    WHEN mode_osm = mode_transit
    THEN 1.0
    WHEN (
      mode_osm = 'trainish' AND mode_transit IN ('train', 'light_rail')
    )
    OR (
      mode_transit = 'trainish' AND mode_osm IN ('train', 'light_rail')
    )
    THEN 1.0
    WHEN mode_transit IS NULL
    THEN @MODE_SIMILARITY_TRANSIT_MODE_UNKNOWN_OR_NOT_UNIQUE
    WHEN mode_osm IS NULL
    THEN @MODE_SIMILARITY_OSM_MODE_UNKNOWN_OR_NOT_UNIQUE
    ELSE 0.0
  END AS similarity_mode,
  globaleid,
  osm_id,
  mode_transit,
  mode_osm
FROM names