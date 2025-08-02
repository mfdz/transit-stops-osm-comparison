MODEL (
  name stage.osm_stop_successors,
  kind FULL
);

WITH cte AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY ref_role, osm_id, ref_idx ASC) AS Rank
  FROM stage.osm_route_members
)
SELECT
  p.osm_id,
  p.member_id AS predesessor,
  s.member_id AS successor
FROM cte AS s
JOIN cte AS p
  ON (
    s.Rank - 1
  ) = p.Rank AND p.osm_id = s.osm_id AND p.ref_role = s.ref_role