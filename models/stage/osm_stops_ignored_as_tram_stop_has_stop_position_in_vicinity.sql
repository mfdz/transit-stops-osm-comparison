MODEL(
	name stage.osm_stops_ignored_as_tram_stop_has_stop_position_in_vicinity,
	kind VIEW,
	description "We ignore PTv1 tram_stops (often tagged in center of tram_stops) if there is at least one identically named stop_position in the vicinity."
); 

SELECT tram_stop.osm_id
  FROM stage.osm_stop_candidates_with_mode_and_type tram_stop
  JOIN stage.osm_stop_candidates_with_mode_and_type s ON tram_stop.name = s.name AND s.lat BETWEEN tram_stop.lat-0.01 AND tram_stop.lat+0.01 AND s.lon BETWEEN tram_stop.lon-0.01 AND tram_stop.lon+0.01
 WHERE tram_stop.type = 'stop'
   AND tram_stop.mode IN ('tram', 'trainish')
   AND tram_stop.railway='tram_stop' 
   AND tram_stop.public_transport is NULL
   AND s.type = 'stop' 
   AND s.mode IN ('tram', 'trainish')
   AND s.public_transport = 'stop_position'
