MODEL (
  name matching.rating_similarity_ifopt,
  kind FULL
);

WITH ifopts AS (
  SELECT
    c.stop_id,
    o.osm_id,
    o.ref AS osm_ifopt
  FROM matching.match_candidates AS c
  JOIN matching.transit_stops AS t
    USING (stop_id)
  JOIN stage.osm_stops AS o
    USING (osm_ID)
)
SELECT
  CASE
    WHEN stop_id = osm_ifopt
    THEN 1.0
    WHEN osm_ifopt IS NULL
    THEN 0.9
    WHEN osm_ifopt LIKE '%' || stop_id || '%'
    THEN 0.95
    WHEN stop_id LIKE osm_ifopt || '%'
    THEN 0.95
    ELSE 0.0
  END AS similarity_ifopt,
  stop_id,
  osm_id,
  osm_ifopt
FROM ifopts