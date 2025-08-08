MODEL (
  name matching.rating_similarity_all,
  kind FULL
);

SELECT
  c.globaleid,
  c.osm_id,
  i.similarity_ifopt,
  m.similarity_mode,
  n.similarity_jaccard,
  p.similarity_platform,
  s.similarity_successors,
  similarity_jaccard / (
    1.0 + distance / 10.0
  ) AS name_distance_rating,
  distance,
  CASE
    WHEN similarity_ifopt = 1.0
    THEN 1.0
    ELSE POWER(
      (
        name_distance_rating * (
          0.5 + 0.5 * similarity_platform
        )
      ),
      (
        1 - similarity_successors * 0.3 - similarity_mode * 0.2
      )
    )
  END AS similarity
FROM matching.match_candidates AS c
LEFT JOIN matching.rating_similarity_ifopt AS i
  ON c.globaleid = i.globaleid AND c.osm_id = i.osm_id
LEFT JOIN matching.rating_similarity_mode AS m
  ON c.globaleid = m.globaleid AND c.osm_id = m.osm_id
LEFT JOIN matching.rating_similarity_name AS n
  ON c.globaleid = n.globaleid AND c.osm_id = n.osm_id
LEFT JOIN matching.rating_similarity_platform_code AS p
  ON c.globaleid = p.globaleid AND c.osm_id = p.osm_id
LEFT JOIN matching.rating_similarity_successor_names AS s
  ON c.globaleid = s.globaleid AND c.osm_id = s.osm_id