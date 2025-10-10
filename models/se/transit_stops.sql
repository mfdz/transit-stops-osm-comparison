MODEL (
  name se.transit_stops,
  kind FULL,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations"
);

WITH number_of_station_quays AS (
  SELECT
    parent_station,
    COUNT(*) AS cnt
  FROM se.stops
  GROUP BY
    parent_station
)
SELECT
  s.stop_id AS stop_id,
  s.parent_station AS parent,
  s.stop_name AS stop_long_name,
  s.stop_name AS locality,
  s.stop_name AS stop_name_without_locality,
  s.platform_code AS assumed_platform,
  n.cnt AS number_of_station_quays,
  s.stop_lat AS latitude,
  s.stop_lon AS longitude,
  '' mode,
  '' route_short_names,
  ST_TRANSFORM(ST_POINT(stop_lat, stop_lon), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM se.stops AS s
WHERE s.stop_id LIKE '%:Quay:%'
LEFT JOIN number_of_station_quays AS n
  ON s.parent_station = n.parent_station
