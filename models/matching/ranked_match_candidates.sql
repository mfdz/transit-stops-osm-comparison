MODEL (
  name matching.ranked_match_candidates,
  kind FULL,
  description "Match candidates above minimum rating, ordered per transit stop (quay/station) by similarity and osm_id."
);

WITH similarity_ranked_match_candidates AS (
  SELECT
    globaleid,
    osm_id,
    similarity,
    ROW_NUMBER() OVER (PARTITION BY globaleId ORDER BY similarity DESC, osm_id ASC) AS stop_ranking
  FROM matching.rating_similarity_all
  WHERE
    similarity > 0.04
)
SELECT
  COALESCE(t.parent, t.globaleid) AS parent_or_station,
  s.*
FROM similarity_ranked_match_candidates AS s
JOIN matching.transit_stops AS t
  ON s.globaleid = t.globaleid
WHERE stop_ranking < 5