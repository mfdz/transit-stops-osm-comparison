MODEL (
  name matching.transit_stops,
  kind VIEW,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations"
);

SELECT
  *
FROM @TRANSIT_STOPS_SCHEMA.transit_stops