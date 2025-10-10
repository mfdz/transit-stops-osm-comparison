MODEL (
  name se.stops,
  kind FULL,
  columns (
    stop_id TEXT,
    stop_lon DOUBLE,
    stop_lat DOUBLE,
    stop_name TEXT,
    platform_code TEXT,
    parent_station TEXT
  ),
  grain (
    stop_id
  )
);
SELECT
  *
FROM READ_CSV('seeds/stops.csv', quote = '"')