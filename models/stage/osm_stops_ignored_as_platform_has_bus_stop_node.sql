MODEL (
  name stage.osm_stops_ignored_as_platform_has_bus_stop_node,
  kind VIEW,
  description "We ignore platforms which have already a bus_stop node, which we assign higher priority 
                  		 (thinking of a bus_station where multiple bus_stops may be assigned to a single platform..)"
);

SELECT
  p.way_id
FROM stage.osm_platform_ways_with_node_refs AS p
SEMI JOIN stage.osm_stop_candidates AS b
  ON p.node_id = b.osm_id