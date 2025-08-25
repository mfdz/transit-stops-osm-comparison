MODEL (
	name matching.directions,
	kind FULL);

SELECT DISTINCT 
  succ.routes AS route_short_name, 
  t.globaleid from_id, t.stop_long_name from_name, 
  t.latitude from_lat, t.longitude from_lon, 
  st2.stop_id to_id, st2.stop_name to_name, st2.stop_lat to_lat, st2.stop_lon to_lon,
  ST_MakeLine(ST_Point(from_lon,from_lat), ST_Point(from_lon+(to_lon-from_lon)/8,from_lat+(to_lat-from_lat)/8)) geometry
FROM matching.matches_with_state t
JOIN stage.gtfs_stops_successors succ ON succ.predecessor_id = t.globaleid
JOIN gtfs.stops st2 ON succ.successor_id=st2.stop_id
WHERE t.match_state='MATCHED_THOUGH_REVERSED_DIR';