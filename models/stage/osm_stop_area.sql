MODEL (
  name stage.osm_stop_area,
  kind VIEW
);

SELECT
  substr(kind,1,1)||id osm_id,
  MAP_EXTRACT_VALUE(tags, 'name') AS "name",
  MAP_EXTRACT_VALUE(tags, 'network') AS network,
  MAP_EXTRACT_VALUE(tags, 'operator') AS "operator",
  MAP_EXTRACT_VALUE(tags, 'mode') AS "mode",
  MAP_EXTRACT_VALUE(tags, 'ref:IFOPT') AS ref_ifopt,
  MAP_EXTRACT_VALUE(tags, 'ref:pt_id') AS ref_pt_id
FROM raw.osm
WHERE
  kind = 'relation' AND MAP_EXTRACT_VALUE(tags, 'public_transport') = 'stop_area'