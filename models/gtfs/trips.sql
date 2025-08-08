MODEL (
  name gtfs.trips,
  kind FULL,
  columns (
    route_id TEXT,
    trip_id TEXT,
    service_id TEXT,
    shape_id TEXT,
    trip_headsign TEXT,
    bikes_allowed SMALLINT,
    trip_short_name TEXT,
    direction_id SMALLINT,
    block_id TEXT
  ),
  grain (
    trip_id
  )
);

SELECT
  *
FROM READ_CSV(
  'zip://seeds/gtfs.zip/trips.txt',
  types = {'trip_short_name': 'VARCHAR'},
  quote = '"'
)