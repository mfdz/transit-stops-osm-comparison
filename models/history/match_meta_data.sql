MODEL (
  name history.match_meta_data,
  kind INCREMENTAL_UNMANAGED,
  columns (
    run_id INT,
    key TEXT,
    value TEXT
  )
);

@DEF(weekly_run, d -> (
  YEAR(d) - 2026
) * 53 + WEEK(d) + 177);

SELECT
  @weekly_run(CURRENT_DATE) AS run_id,
  "key",
  CASE
    WHEN "key" = 'match_timestamp'
    THEN STRFTIME(TO_TIMESTAMP("value"::DOUBLE), '%x %X')
    ELSE "value"
  END AS "value"
FROM matching.match_meta_data