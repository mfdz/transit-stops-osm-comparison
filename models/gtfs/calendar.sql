MODEL (
  name gtfs.calendar,
  kind FULL,
  columns (
    service_id TEXT,
    start_date DATE,
    end_date DATE,
    monday BOOLEAN,
    tuesday BOOLEAN,
    wednesday BOOLEAN,
    thursday BOOLEAN,
    friday BOOLEAN,
    saturday BOOLEAN,
    sunday BOOLEAN
  ),
  grain (
    service_id
  )
);

SELECT
  service_id,
  MAKE_DATE(
    SUBSTRING('' || start_date, 1, 4)::INT,
    SUBSTRING('' || start_date, 5, 2)::INT,
    SUBSTRING('' || start_date, 7, 2)::INT
  ) AS start_date,
  MAKE_DATE(
    SUBSTRING('' || end_date, 1, 4)::INT,
    SUBSTRING('' || end_date, 5, 2)::INT,
    SUBSTRING('' || end_date, 7, 2)::INT
  ) AS end_date,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
FROM READ_CSV('zip://seeds/'||@TRANSIT_STOPS_SCHEMA||'/gtfs.zip/calendar.txt')