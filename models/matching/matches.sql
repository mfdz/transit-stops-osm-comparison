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
  FROM matching.ranked_match_candidates AS rmc
  WHERE
    NOT rmc.parent_or_station IN (
      SELECT
        parent_or_station
      FROM matching.ambiguously_matched_stations
    )
    AND stop_ranking = 1
  UNION ALL
  SELECT
    parent_or_station,
    globaleid,
    osm_id,
    similarity
  FROM matching.matches_for_ambiguously_matched_stations
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