AUDIT (
  name transit_osm_candidate_pairs_unique,
  blocking FALSE
);

SELECT
  osm_id,
  globaleid,
  COUNT(*) AS cnt
FROM matching.match_candidates
GROUP BY
  osm_id,
  globaleid
HAVING
  cnt > 1