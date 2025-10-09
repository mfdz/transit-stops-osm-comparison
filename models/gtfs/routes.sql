MODEL (
  name gtfs.routes,
  kind FULL,
  columns (
    agency_id TEXT,
    route_id TEXT,
    route_type SMALLINT,
    route_long_name TEXT,
    route_short_name TEXT,
    route_color TEXT
  ),
  grain (
    route_id
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/gtfs.zip/routes.txt', quote = '"')