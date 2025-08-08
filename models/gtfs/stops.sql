MODEL (
  name gtfs.stops,
  kind FULL,
  columns (
    stop_id TEXT,
    stop_lon DOUBLE,
    stop_lat DOUBLE,
    stop_name TEXT,
    location_type INT,
    parent_station TEXT,
    level_id TEXT,
    platform_code TEXT
  ),
  grain (
    stop_id
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/gtfs.zip/stops.txt', quote = '"')