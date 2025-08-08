MODEL (
  name stage.osm_stops_successor_name,
  kind FULL
);

/* names of successors stops of predecessor */
SELECT
  s.predecessor AS osm_id,
  o.name AS successor_name
FROM stage.osm_stop_successors AS s
JOIN stage.osm_stop_candidates AS o
  ON s.successor = o.osm_id
WHERE
  NOT o.name IS NULL
UNION
/* names of successors stops of predecessor stops nodes on platforms */
SELECT
  bus_stop.osm_id,
  o.name AS successor_name
FROM stage.osm_stop_candidates AS bus_stop
JOIN stage.osm_platform_ways_with_node_refs AS pn
  ON bus_stop.osm_id = pn.node_id
JOIN stage.osm_stop_successors AS s
  ON s.predecessor = pn.way_id
JOIN stage.osm_stop_candidates AS o
  ON s.successor = o.osm_id
WHERE
  NOT o.name IS NULL