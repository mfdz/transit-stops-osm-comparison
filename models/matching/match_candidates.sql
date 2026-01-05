MODEL (
  name matching.match_candidates,
  kind FULL,
  description "",
  audits (
    transit_osm_candidate_pairs_unique
  )
);

WITH filtered_match_candidates AS (
  SELECT
    mv.*
  FROM matching.match_candidates_in_vicinity AS mv
  JOIN stage.osm_stops AS o
    USING (osm_id)
  JOIN matching.transit_stops AS t
    USING (stop_id)
  WHERE
    NOT COALESCE(
      (
        o.mode IN ('trainish', 'train', 'light_rail', 'tram', 'ferry')
        AND t.mode IN ('bus')
      )
      OR (
        o.mode IN ('bus')
        AND t.mode IN ('tram', 'light_rail', 'train', 'trainish', 'ferry')
      ),
      FALSE
    )
    OR o.ref = t.stop_id
), distance_ranked_match_candidates AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY stop_id ORDER BY distance ASC) AS stop_ranking
  FROM filtered_match_candidates
)
SELECT
  *
FROM distance_ranked_match_candidates
WHERE
  stop_ranking <= LEAST(number_of_station_quays + 5, @MAX_NUMBER_OF_CANDIDATES_PER_QUAY)