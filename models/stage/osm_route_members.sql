MODEL (
  name stage.osm_route_members,
  kind VIEW
);

SELECT
  'r'||id osm_id, 
  substr(ref_type,1,1)||ref member_id,
  ref_role,
  ref_idx 
FROM (
  SELECT
    r.id,
    UNNEST(refs) AS ref,
    UNNEST(ref_types) AS ref_type,
    UNNEST(ref_roles) AS ref_role,
    UNNEST(RANGE(0, LENGTH(refs))) AS ref_idx
  FROM raw.osm AS r
  WHERE
    kind = 'relation'
    AND MAP_EXTRACT_VALUE(tags, 'route') IN ('light_rail', 'bus', 'ferry', 'tram', 'train')
)
WHERE
  ref_role IN ('stop', 'platform')