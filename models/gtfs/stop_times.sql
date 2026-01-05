MODEL (
  name gtfs.stop_times,
  kind FULL,
  columns (
    trip_id TEXT,
    stop_id TEXT,
    stop_sequence INT,
    arrival_time TEXT,
    departure_time TEXT,
    pickup_type SMALLINT,
    drop_off_type SMALLINT
  ),
  grain (trip_id, stop_sequence)
);

SELECT
  *
FROM READ_CSV(
  'zip://seeds/' || @TRANSIT_STOPS_SCHEMA || '/gtfs.zip/stop_times.txt',
  types = {'arrival_time': 'VARCHAR', 'departure_time': 'VARCHAR'},
  quote = '"'
)