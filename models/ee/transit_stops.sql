MODEL (
  name ee.transit_stops,
  kind FULL,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations"
);

WITH route_short_names_per_stop_id AS (
  SELECT
    stop_id,
    LISTAGG(route_short_name, ',') AS route_short_names
  FROM stage.gtfs_stops_route_short_names
  GROUP BY
    stop_id
)
SELECT
  s.stop_id AS stop_id,
  s.stop_name AS stop_long_name,
  s.stop_name AS locality,
  s.stop_name AS stop_name_without_locality,
  s.platform_code AS assumed_platform,
  1 number_of_station_quays,
  '' parent,
  s.stop_lat AS latitude,
  s.stop_lon AS longitude,
  CASE
    WHEN gst.route_type = 3 
    THEN 'bus'
    WHEN gst.route_type = 2
    THEN 'train'
    WHEN gst.route_type = 0
    THEN 'tram'
    WHEN gst.route_type = 1
    THEN 'light_rail'
    WHEN gst.route_type = 4
    THEN 'ferry'
    WHEN gst.route_type = 7
    THEN 'funicular'
    ELSE NULL
  END AS mode,
  route_short_names,
  ST_TRANSFORM(ST_POINT(stop_lat, stop_lon), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM gtfs.stops AS s
LEFT JOIN stage.gtfs_stop_types AS gst
  ON gst.stop_id = s.stop_id
LEFT JOIN route_short_names_per_stop_id AS rsn
  ON rsn.stop_id = s.stop_id
