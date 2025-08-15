MODEL (
  name stage.osm_stops_ignored_all,
  kind VIEW,
  description "All IDs of stops to be ignored"
);

SELECT
  *
FROM stage.osm_stops_ignored_as_halt_has_stop_position_in_vicinity
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_platform_has_bus_stop_node
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_platform_has_trainish_stop_position_in_vicinity
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_platform_in_vicinity
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_platforms_exist_in_stop_area
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_stop_position_has_bus_platform_in_vicinity
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_stop_position_is_platform_node
UNION ALL
SELECT
  *
FROM stage.osm_stops_ignored_as_tram_stop_has_stop_position_in_vicinity