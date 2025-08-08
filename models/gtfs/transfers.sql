MODEL (
  name gtfs.transfers,
  kind FULL,
  columns (
    from_stop_id TEXT,
    to_stop_id TEXT,
    transfer_type SMALLINT,
    min_transfer_time TEXT,
    from_route_id TEXT,
    to_route_id TEXT,
    from_trip_id TEXT,
    to_trip_id TEXT
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/gtfs.zip/transfers.txt')