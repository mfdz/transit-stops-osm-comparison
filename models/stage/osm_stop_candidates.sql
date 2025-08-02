MODEL (
  name stage.osm_stop_candidates,
  kind FULL
);

WITH stop_features AS (
  SELECT
    *,
    substr(kind,1,1)||id osm_id
  FROM raw.osm
  WHERE
    (
      MAP_EXTRACT_VALUE(tags, 'railway') IN ('stop', 'tram_stop', 'halt')
      OR MAP_EXTRACT_VALUE(tags, 'highway') = 'bus_stop'
      OR MAP_EXTRACT_VALUE(tags, 'public_transport') IN ('stop_position', 'platform')
    )
), platform_ways AS (
  SELECT
    *
  FROM stop_features
  WHERE
    kind = 'way'
), platform_stops_stations_nodes AS (
  SELECT
    *
  FROM stop_features
  WHERE
    kind = 'node'
)
SELECT
  substr(kind,1,1)||id osm_id,
  MAP_EXTRACT_VALUE(tags, 'name') AS "name",
  MAP_EXTRACT_VALUE(tags, 'network') AS "network",
  MAP_EXTRACT_VALUE(tags, 'operator') AS "operator",
  MAP_EXTRACT_VALUE(tags, 'railway') AS "railway",
  MAP_EXTRACT_VALUE(tags, 'highway') AS "highway",
  MAP_EXTRACT_VALUE(tags, 'public_transport') AS "public_transport",
  MAP_EXTRACT_VALUE(tags, 'ref:IFOPT') AS ref_ifopt,
  MAP_EXTRACT_VALUE(tags, 'ref:pt_id') AS ref_pt_id,
  MAP_EXTRACT_VALUE(tags, 'ref') AS "ref",
  MAP_EXTRACT_VALUE(tags, 'local_ref') AS local_ref,
  MAP_EXTRACT_VALUE(tags, 'kerb:approach_aid') AS "kerb_approach_aid",
  MAP_EXTRACT_VALUE(tags, 'wheelchair') AS "wheelchair",
  MAP_EXTRACT_VALUE(tags, 'tactile_paving') AS "tactile_paving",
  MAP_EXTRACT_VALUE(tags, 'bus') = 'yes' AS "bus",
  MAP_EXTRACT_VALUE(tags, 'train') = 'yes' AS "train",
  MAP_EXTRACT_VALUE(tags, 'tram') = 'yes' AS "tram",
  MAP_EXTRACT_VALUE(tags, 'light_rail') = 'yes' AS "light_rail",
  MAP_EXTRACT_VALUE(tags, 'ferry') = 'yes' AS "ferry",
  MAP_EXTRACT_VALUE(tags, 'funicular') = 'yes' AS "funicular",
  lat,
  lon,
  geometry
FROM (
  SELECT
    pw.*
    EXCLUDE (lat, lon),
    ST_X(geometry) AS lon,
    ST_Y(geometry) AS lat,
    geometry
  FROM platform_ways AS pw
  JOIN stage.osm_platform_ways_with_centroid AS c
    USING (osm_id)
  UNION ALL
  SELECT
    *
    EXCLUDE (lat, lon),
    lon,
    lat,
    ST_POINT(lon, lat) AS geometry
  FROM platform_stops_stations_nodes
)