AUDIT (
  name transit_osm_candidate_pairs_unique,
  blocking FALSE
);

SELECT
  osm_id,
  stop_id,
  COUNT(*) AS cnt
FROM matching.match_candidates
GROUP BY
  osm_id,
  stop_id
HAVING
  cnt > 1