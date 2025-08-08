MODEL (
  name stage.osm_stop_area_members,
  kind VIEW
);

SELECT
  *,
  SUBSTRING(ref_type, 1, 1) || ref AS member_id
FROM (
  SELECT
    SUBSTRING(r.kind, 1, 1) || r.id AS osm_id,
    UNNEST(refs) AS ref,
    UNNEST(ref_types) AS ref_type,
    UNNEST(ref_roles) AS ref_role,
    UNNEST(RANGE(0, LENGTH(refs))) AS ref_idx
  FROM raw.osm AS r
  WHERE
    kind = 'relation' AND MAP_EXTRACT_VALUE(tags, 'public_transport') = 'stop_area'
)
WHERE
  ref_role IN ('stop', 'platform')