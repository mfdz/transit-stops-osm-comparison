MODEL (
  name history.match_stats,
  kind INCREMENTAL_UNMANAGED,
  columns (
    run_id INT,
    district TEXT,
    key TEXT,
    value INT
  )
);

@DEF(weekly_run, d -> (
  YEAR(d) - 2026
) * 53 + WEEK(d) + 177);

SELECT
  @weekly_run(CURRENT_DATE) AS run_id,
  region AS district,
  match_state AS "key",
  count AS "value"
FROM result.match_state_per_region