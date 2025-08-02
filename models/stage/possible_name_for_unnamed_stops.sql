MODEL (
	name stage.possible_name_for_unnamed_stops,
	kind FULL,
	description "For unnamed stops, preferable existing names of platform ways or stop areas they are part of is used, else (for bus platforms only) the name of other close by stop_positions"
);

WITH platform_way_names AS
(SELECT p.node_id, pw.name 
  FROM stage.osm_platform_ways_with_node_refs p
  JOIN stage.osm_stop_candidates pw ON pw.osm_id=p.way_id
WHERE pw.name is not NULL),
stop_area_names AS (
SELECT p.member_id, area.name 
  FROM stage.osm_stop_area_members p
  JOIN stage.osm_stop_area area ON area.osm_id=p.osm_id
WHERE area.name is not NULL),
longest_name_of_stop_close_by AS (
SELECT no_name.osm_id, FIRST(close.name ORDER BY LEN(close.name) DESC) "name"
FROM stage.osm_stop_candidates no_name
JOIN stage.osm_stop_candidates_with_mode_and_type close ON close.lat BETWEEN no_name.lat - 0.0001 AND no_name.lat + 0.0001 AND close.lon BETWEEN no_name.lon - 0.0001 AND no_name.lon +0.0001 AND close.name is not null
WHERE no_name.name IS NULL
  AND close.mode='bus' AND close.public_transport='stop_position'
  AND no_name.type='platform'
GROUP BY no_name.osm_id
)
SELECT no_name.osm_id, COALESCE(pwn.name, san.name, close.name) "name", CASE WHEN pwn.name IS NOT NULL OR san.name IS NOT NULL THEN 0 ELSE 1 END EMPTY_NAME
  FROM stage.osm_stop_candidates_with_mode_and_type no_name
  LEFT JOIN platform_way_names pwn ON no_name.osm_id = pwn.node_id
  LEFT JOIN stop_area_names san ON no_name.osm_id = san.member_id
  LEFT JOIN longest_name_of_stop_close_by close ON no_name.osm_id=close.osm_id
 WHERE no_name.name IS NULL AND NOT (pwn.name IS NULL AND san.name IS NULL AND close.name IS NULL)
