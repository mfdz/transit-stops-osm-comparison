MODEL (
  name stage.osm_stops,
  kind VIEW
);

SELECT
  c.* EXCLUDE (name),
  COALESCE(c.name, n.name) "name",
  CASE
    WHEN c.name IS NOT NULL THEN 0
    WHEN n.name IS NOT NULL THEN n.empty_name
    ELSE 1
  END empty_name
FROM stage.osm_stop_candidates_with_mode_and_type c
LEFT JOIN stage.possible_name_for_unnamed_stops n on c.osm_id = n.osm_id