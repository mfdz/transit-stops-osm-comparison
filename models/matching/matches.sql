MODEL (
  name matching.matches,
  kind FULL
);

WITH all_matches AS (
  SELECT
    parent_or_station,
    globaleid,
    osm_id,
    similarity
  FROM matching.perfect_matches
  UNION ALL
  SELECT
    mc.parent_or_station,
    m.globaleid,
    m.osm_id,
    mc.similarity
  FROM matching.matches_for_ambiguously_matched_stations m
  JOIN matching.ranked_match_candidates mc ON m.globaleid=mc.globaleid AND m.osm_id=mc.osm_id 
), all_matches_by_osm_id_sorted AS (
  /* For each osm_id, we keep only the match with highest similarity. */ /* If both have same, least ifopt is choosen to get deterministic results */ /* TODO this filters out MATCHED_AMBIGUOUSLY. We don't want this! */
  SELECT
    ROW_NUMBER() OVER (PARTITION BY osm_id ORDER BY similarity DESC, globaleid ASC) AS RowNum,
    *
  FROM all_matches
)
SELECT
  *
  EXCLUDE (RowNum)
FROM all_matches_by_osm_id_sorted
WHERE
  RowNum = 1