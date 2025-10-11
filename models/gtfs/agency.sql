MODEL (
  name gtfs.agency,
  kind FULL,
  columns (
    agency_id TEXT,
    agency_name TEXT,
    agency_url TEXT,
    agency_timezone TEXT
  ),
  grain (
    agency_id
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/'||@TRANSIT_STOPS_SCHEMA||'/gtfs.zip/agency.txt', quote = '"')