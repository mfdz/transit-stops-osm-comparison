MODEL (
  name stage.gtfs_stop_types,
  kind FULL
);

WITH route_types_per_stop AS (
  SELECT DISTINCT
    stop_id,
    CASE
      WHEN route_type BETWEEN 700 AND 799 OR route_type = 1501 OR route_type = 300
      THEN 3
      WHEN route_type IN ('100', '101', '102', '103', '106', '109')
      THEN 2
      WHEN route_type BETWEEN 400 AND 499
      THEN 1
      WHEN route_type BETWEEN 900 AND 999
      THEN 0
      WHEN route_type BETWEEN 1000 AND 1099
      THEN 5
      ELSE route_type
    END AS route_type
  FROM gtfs.stop_times AS st
  JOIN gtfs.trips
    USING (trip_id)
  JOIN gtfs.routes
    USING (route_id)
), unique_types AS (
  SELECT
    stop_id,
    COUNT(*) AS cnt
  FROM route_types_per_stop
  GROUP BY
    stop_id
  HAVING
    cnt = 1
)
SELECT
  stop_id,
  route_type
FROM route_types_per_stop
WHERE
  stop_id IN (
    SELECT
      stop_id
    FROM unique_types
  )