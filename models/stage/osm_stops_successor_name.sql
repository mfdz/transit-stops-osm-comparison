MODEL (
  name stage.osm_stops_successor_name,
  kind FULL
);

SELECT
  predesessor AS osm_id,
  LISTAGG(name, '/') AS succ_name
FROM (
  /* names of successors stops of predecessor */
  SELECT
    s.predesessor,
    o.name
  FROM stage.osm_stop_successors AS s
  JOIN stage.osm_stop_candidates AS o
    ON s.successor = o.osm_id
  WHERE
    NOT o.name IS NULL
  UNION
  /* names of successors stops of predesessor stops nodes on platforms */
  SELECT
    bus_stop.osm_id,
    o.name
  FROM stage.osm_stop_candidates AS bus_stop
  JOIN stage.osm_platform_ways_with_node_refs AS pn
    ON bus_stop.osm_id = pn.node_id
  JOIN stage.osm_stop_successors AS s
    ON s.predesessor = pn.way_id
  JOIN stage.osm_stop_candidates AS o
    ON s.successor = o.osm_id
  WHERE
    NOT o.name IS NULL
)
GROUP BY
  predesessor