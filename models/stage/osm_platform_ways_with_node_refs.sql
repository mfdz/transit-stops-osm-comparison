MODEL (
  name stage.osm_platform_ways_with_node_refs,
  kind FULL
);
WITH platform_nodes AS (
SELECT
  id,
  UNNEST(refs) AS ref,
  UNNEST(RANGE(0, LENGTH(refs))) AS ref_idx
FROM raw.osm
WHERE
  kind = 'way' AND MAP_EXTRACT_VALUE(tags, 'public_transport') = 'platform'
)
SELECT *, 'w'||id way_id, 'n'||ref node_id
FROM platform_nodes