MODEL (
  name result.regions,
  kind VIEW
);

SELECT DISTINCT
  SUBSTRING(globaleID, 0, STRPOS(SUBSTRING(globaleID || ':', 4), ':') + 3) AS region
FROM matching.transit_stops