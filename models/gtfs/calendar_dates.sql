MODEL (
  name gtfs.calendar_dates,
  kind FULL,
  columns (
    service_id TEXT,
    date DATE,
    exception_type SMALLINT
  ),
  grain (
    service_id
  )
);

SELECT
  service_id,
  MAKE_DATE(
    SUBSTRING('' || date, 1, 4)::INT,
    SUBSTRING('' || date, 5, 2)::INT,
    SUBSTRING('' || date, 7, 2)::INT
  ) AS date,
  exception_type
FROM READ_CSV('zip://seeds/gtfs.zip/calendar_dates.txt')