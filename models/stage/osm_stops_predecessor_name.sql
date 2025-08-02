MODEL (
  name stage.osm_stops_predecessor_name,
  kind FULL
);

SELECT
  successor AS osm_id,
  LISTAGG(name, '/') AS pred_name
FROM (
  /* names of predecessors stops of successor */
  SELECT
    s.successor,
    o.name
  FROM stage.osm_stop_successors AS s
  JOIN stage.osm_stop_candidates AS o
    ON s.predesessor = o.osm_id
  WHERE
    NOT o.name IS NULL
  UNION
  /* names of precessors stops of successor stops nodes on platforms */
  SELECT
    bus_stop.osm_id,
    o.name
  FROM stage.osm_stop_candidates AS bus_stop
  JOIN stage.osm_platform_ways_with_node_refs AS pn
    ON bus_stop.osm_id = pn.node_id
  JOIN stage.osm_stop_successors AS s
    ON s.successor = pn.way_id
  JOIN stage.osm_stop_candidates AS o
    ON s.predesessor = o.osm_id
  WHERE
    NOT o.name IS NULL
)
GROUP BY
  successor