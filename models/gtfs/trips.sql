MODEL (
  name gtfs.trips,
  kind FULL,
  columns (
    route_id TEXT,
    trip_id TEXT,
    service_id TEXT,
    trip_headsign TEXT
  ),
  grain (
    trip_id
  )
);

SELECT
  *
FROM READ_CSV(
  'zip://seeds/' || @TRANSIT_STOPS_SCHEMA || '/gtfs.zip/trips.txt',
  quote = '"',
  types = {'route_id': 'VARCHAR'}
)