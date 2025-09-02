MODEL (
  name matching.rating_similarity_platform_code,
  kind FULL
);

WITH platform_codes AS (
  SELECT
    c.stop_id,
    o.osm_id,
    t.assumed_platform AS assumed_platform_code_transit,
    nullif(o.assumed_platform,'') AS assumed_platform_code_osm
  FROM matching.match_candidates AS c
  JOIN matching.transit_stops AS t
    USING (stop_id)
  JOIN stage.osm_stops AS o
    USING (osm_ID)
)
SELECT
  CASE
    -- Both are null, that's kind of indifferant, but worse than both matching
    WHEN assumed_platform_code_transit IS NULL AND assumed_platform_code_osm IS NULL
    THEN 0.9
    WHEN assumed_platform_code_transit = assumed_platform_code_osm
    THEN 1.0
    -- If only one is null, it's worse than both null, as either side should matcht
    WHEN assumed_platform_code_transit IS NULL OR assumed_platform_code_osm IS NULL
    THEN 0.85
    -- if both are not null not equal, they presumably don't match
    ELSE 0.0
  END AS similarity_platform,
  *
FROM platform_codes