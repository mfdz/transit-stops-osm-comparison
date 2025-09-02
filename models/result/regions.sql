MODEL (
  name result.regions,
  kind VIEW
);

SELECT DISTINCT
  SUBSTRING(stop_id, 0, STRPOS(SUBSTRING(stop_id || ':', 4), ':') + 3) AS region
FROM matching.transit_stops