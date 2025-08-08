MODEL (
  name stage.gtfs_stops_predecessor_names,
  kind FULL
);

SELECT
  s.successor_id AS stop_id,
  predecessor_id,
  CASE WHEN is_long_distance THEN t.locality ELSE t.stop_name_without_locality END AS short_predecessor_name,
  st.stop_name AS long_predecessor_name
FROM stage.gtfs_stops_successors AS s
JOIN gtfs.stops AS st
  ON s.predecessor_id = st.stop_id
LEFT JOIN matching.transit_stops AS t
  ON s.predecessor_id = t.globaleid