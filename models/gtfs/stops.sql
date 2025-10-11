MODEL (
  name gtfs.stops,
  kind FULL,
  columns (
    stop_id TEXT,
    stop_lon DOUBLE,
    stop_lat DOUBLE,
    stop_name TEXT,
    platform_code TEXT
  ),
  grain (
    stop_id
  )
);

SELECT
  *, '' platform_code
FROM READ_CSV('zip://seeds/'||@TRANSIT_STOPS_SCHEMA||'/gtfs.zip/stops.txt', quote = '"')