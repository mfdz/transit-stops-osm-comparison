MODEL (
	name stage.osm_stops_ignored_as_platform_with_same_ifopt_as_stop_position_in_vicinity,
	kind VIEW,
	description "We ignore stop_positions for buses if there is a platform with the same IFOPT in the vicinity."
);

SELECT h.osm_id
  FROM stage.osm_stop_candidates_with_mode_and_type h, stage.osm_stop_candidates_with_mode_and_type s
 WHERE h.type = 'stop'
   AND h.mode = 'bus'
   AND h.ref = s.ref 
   AND s.type = 'platform'
   AND s.ref_key = 'ref:IFOPT'
   AND s.ref_key = h.ref_key
   AND s.lat BETWEEN h.lat-0.01 AND h.lat+0.01 
   AND s.lon BETWEEN h.lon-0.01 AND h.lon+0.
