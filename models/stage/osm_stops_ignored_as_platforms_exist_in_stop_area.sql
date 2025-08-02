MODEL (
	name stage.osm_stops_ignored_as_platforms_exist_in_stop_area,
	kind VIEW,
	description "We ignore bus stop_positions from stop_areas, where there are also platforms with mode bus"
);

SELECT s.osm_id 
  FROM stage.osm_stop_area_members mp
  JOIN stage.osm_stop_area_members ms USING(osm_id)
  JOIN stage.osm_stop_candidates_with_mode_and_type p ON mp.member_id=p.osm_id 
  JOIN stage.osm_stop_candidates_with_mode_and_type s ON ms.member_id=s.osm_id
 WHERE p.mode = 'bus' AND p.type = 'platform'
   AND s.mode = 'bus' AND s.type='stop'