MODEL (
  name result.match_state_per_region,
  kind VIEW
);

SELECT
  SUBSTRING(t.stop_id, 0, STRPOS(SUBSTRING(t.stop_id || ':', 4), ':') + 3) AS region,
  match_state,
  COUNT(*) AS count
FROM matching.matches_with_state AS t
GROUP BY
  SUBSTRING(t.stop_id, 0, STRPOS(SUBSTRING(t.stop_id || ':', 4), ':') + 3),
  match_state