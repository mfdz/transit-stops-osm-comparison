MODEL (
  name stage.gtfs_stops_route_short_names,
  kind FULL
);

SELECT DISTINCT
  s.stop_id,
  r.route_short_name
FROM gtfs.stop_times AS s
JOIN gtfs.trips AS t
  USING (trip_id)
JOIN gtfs.routes AS r
  USING (route_id)
ORDER BY
  s.stop_id,
  r.route_short_name