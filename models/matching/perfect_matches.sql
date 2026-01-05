MODEL (
  name matching.perfect_matches,
  kind VIEW,
  description "This view comprises all match candidates which are considered unquestionable. These are matches
    where similiarity is 1.0 (usually because ifopts match perfectly) or the official stop is a station (not a quay), and
    thus all (ambiguous) match candidates are considered equally."
);

SELECT
  *
FROM matching.ranked_match_candidates AS c
WHERE
  similarity = 1
UNION
SELECT
  *
FROM matching.ranked_match_candidates AS s
WHERE
  parent_or_station = stop_id