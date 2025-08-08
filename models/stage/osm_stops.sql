MODEL (
  name stage.osm_stops,
  kind FULL
);

SELECT
  c.*
  EXCLUDE (name),
  COALESCE(c.name, n.name) AS "name",
  CASE
    WHEN NOT c.name IS NULL
    THEN 0
    WHEN NOT n.name IS NULL
    THEN n.empty_name
    ELSE 1
  END AS empty_name
FROM stage.osm_stop_candidates_with_mode_and_type AS c
LEFT JOIN stage.possible_name_for_unnamed_stops AS n
  ON c.osm_id = n.osm_id
WHERE
  NOT c.osm_id IN (
    SELECT
      osm_id
    FROM stage.osm_stops_ignored_all
  )