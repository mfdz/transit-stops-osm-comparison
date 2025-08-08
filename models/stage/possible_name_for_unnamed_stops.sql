MODEL (
  name stage.possible_name_for_unnamed_stops,
  kind FULL,
  description "For unnamed stops, preferable existing names of platform ways or stop areas they are part of is used, else (for bus platforms only) the name of other close by stop_positions"
);

WITH platform_way_names AS (
  SELECT
    p.node_id,
    FIRST(pw.name ORDER BY LENGTH(pw.name)) AS name
  FROM stage.osm_platform_ways_with_node_refs AS p
  JOIN stage.osm_stop_candidates AS pw
    ON pw.osm_id = p.way_id
  WHERE
    NOT pw.name IS NULL
  GROUP BY
    p.node_id
), stop_area_names AS (
  SELECT
    p.member_id,
    FIRST(area.name ORDER BY LENGTH(area.name) DESC) AS "name"
  FROM stage.osm_stop_area_members AS p
  JOIN stage.osm_stop_area AS area
    ON area.osm_id = p.osm_id
  WHERE
    NOT area.name IS NULL
  GROUP BY
    p.member_id
), longest_name_of_stop_close_by AS (
  SELECT
    no_name.osm_id,
    FIRST(close.name ORDER BY LENGTH(close.name) DESC) AS "name"
  FROM stage.osm_stop_candidates AS no_name
  JOIN stage.osm_stop_candidates_with_mode_and_type AS close
    ON close.lat BETWEEN no_name.lat - 0.0001 AND no_name.lat + 0.0001
    AND close.lon BETWEEN no_name.lon - 0.0001 AND no_name.lon + 0.0001
    AND NOT close.name IS NULL
  WHERE
    no_name.name IS NULL
    AND close.mode = 'bus'
    AND close.public_transport = 'stop_position'
    AND no_name.type = 'platform'
  GROUP BY
    no_name.osm_id
)
SELECT
  no_name.osm_id,
  COALESCE(pwn.name, san.name, close.name) AS "name",
  CASE WHEN NOT pwn.name IS NULL OR NOT san.name IS NULL THEN 0 ELSE 1 END AS EMPTY_NAME
FROM stage.osm_stop_candidates_with_mode_and_type AS no_name
LEFT JOIN platform_way_names AS pwn
  ON no_name.osm_id = pwn.node_id
LEFT JOIN stop_area_names AS san
  ON no_name.osm_id = san.member_id
LEFT JOIN longest_name_of_stop_close_by AS close
  ON no_name.osm_id = close.osm_id
WHERE
  no_name.name IS NULL
  AND NOT (
    pwn.name IS NULL AND san.name IS NULL AND close.name IS NULL
  )