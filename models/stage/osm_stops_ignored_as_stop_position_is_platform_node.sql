MODEL (
  name stage.osm_stops_ignored_as_stop_position_is_platform_node,
  kind VIEW,
  description "We ignore stop positions on platforms like n4983922907, n4983922908, n4983924926, n4983924928 (9 occ in bw)"
);

SELECT
  c.osm_id
FROM stage.osm_stop_candidates AS c
JOIN stage.osm_platform_ways_with_node_refs AS pn
  ON pn.node_id = c.osm_id AND public_transport = 'stop_position'