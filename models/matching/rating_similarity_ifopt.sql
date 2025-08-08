MODEL (
  name matching.rating_similarity_ifopt,
  kind FULL
);

WITH ifopts AS (
  SELECT
    c.globaleid,
    o.osm_id,
    o.ref AS osm_ifopt
  FROM matching.match_candidates AS c
  JOIN matching.transit_stops AS t
    USING (globaleid)
  JOIN stage.osm_stops AS o
    USING (osm_ID)
)
SELECT
  CASE
    WHEN globaleid = osm_ifopt
    THEN 1.0
    WHEN osm_ifopt IS NULL
    THEN 0.9
    WHEN osm_ifopt LIKE '%' || globaleid || '%'
    THEN 0.95
    WHEN globaleid LIKE osm_ifopt || '%'
    THEN 0.95
    ELSE 0.0
  END AS similarity_ifopt,
  globaleid,
  osm_id,
  osm_ifopt
FROM ifopts