MODEL (
  name matching.ranked_match_candidates,
  kind FULL,
  description "Match candidates above minimum rating, ordered per transit stop (quay/station) by similarity and osm_id."
);

WITH similarity_ranked_match_candidates AS (
  SELECT
    stop_id,
    osm_id,
    similarity,
    ROW_NUMBER() OVER (PARTITION BY stop_id ORDER BY similarity DESC, osm_id ASC) AS stop_ranking
  FROM matching.rating_similarity_all
  WHERE
    similarity > 0.04
)
SELECT
  COALESCE(t.parent, t.stop_id) AS parent_or_station,
  s.*
FROM similarity_ranked_match_candidates AS s
JOIN matching.transit_stops AS t
  ON s.stop_id = t.stop_id
WHERE
  stop_ranking < 5