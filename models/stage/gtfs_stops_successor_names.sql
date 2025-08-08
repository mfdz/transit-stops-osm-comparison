MODEL (
  name stage.gtfs_stops_successor_names,
  kind FULL
);

SELECT
  s.predecessor_id AS stop_id,
  successor_id,
  CASE WHEN is_long_distance THEN t.locality ELSE t.stop_name_without_locality END AS short_successor_name,
  st.stop_name AS long_successor_name
FROM stage.gtfs_stops_successors AS s
JOIN gtfs.stops AS st
  ON s.successor_id = st.stop_id
LEFT JOIN matching.transit_stops AS t
  ON s.successor_id = t.globaleid