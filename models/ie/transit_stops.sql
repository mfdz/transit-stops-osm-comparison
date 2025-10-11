MODEL (
  name ie.transit_stops,
  kind FULL,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations",
  columns (
      stop_id TEXT,
      stop_long_name TEXT,
      locality TEXT,
      stop_name_without_locality TEXT,
      assumed_platform TEXT,
      number_of_station_quays INTEGER,
      parent TEXT,
      latitude DOUBLE,
      longitude DOUBLE,
      mode TEXT,
      route_short_names TEXT,
      projected_geometry GEOMETRY,
    ),
);

WITH number_of_station_quays AS (
  SELECT
    hst_id,
    COUNT(*) AS cnt
  FROM "at".steige
  GROUP BY
    hst_id
)
SELECT
  s.AtcoCode AS stop_id,
  TRIM(s.CommonName||' '||s.street) AS stop_long_name,
  s.CommonName AS locality,
  COALESCE(s.street,s.CommonName) AS stop_name_without_locality,
  '' AS assumed_platform,
  NULL number_of_station_quays,
  NULL parent,
  s.latitude AS latitude,
  s.longitude AS longitude,
  NULL "mode",
  NULL AS route_short_names,
  ST_TRANSFORM(ST_POINT(latitude, longitude), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM "ie".naptan AS s
WHERE s.status ='active'

