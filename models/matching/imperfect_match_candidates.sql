MODEL (
  name matching.imperfect_match_candidates,
  kind FULL
);

SELECT
  *
FROM matching.ranked_match_candidates
WHERE
  NOT stop_id IN (
    SELECT
      stop_id
    FROM matching.perfect_matches
  )
  AND NOT osm_id IN (
    -- Only ignore osm stops which are a 100% match.
    SELECT
      osm_id
    FROM matching.perfect_matches
    WHERE similarity=1.0
  )