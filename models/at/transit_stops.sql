MODEL (
  name at.transit_stops,
  kind FULL,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations"
);

WITH number_of_station_quays AS (
  SELECT
    hst_id,
    COUNT(*) AS cnt
  FROM "at".steige
  GROUP BY
    hst_id
)
SELECT
  s.stg_globid AS stop_id,
  s.stg_name AS stop_long_name,
  s.stg_name AS locality,
  s.stg_name AS stop_name_without_locality,
  '' AS assumed_platform,
  n.cnt number_of_station_quays,
  st.hst_globid parent,
  s.stg_y AS latitude,
  s.stg_x AS longitude,
  '' "mode",
  linien AS route_short_names,
  ST_TRANSFORM(ST_POINT(stg_y, stg_x), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM "at".steige AS s
LEFT JOIN number_of_station_quays AS n
  ON s.hst_id = n.hst_id
LEFT JOIN "at".haltestellen AS st
  ON s.hst_id = st.hst_id
UNION
SELECT
  s.hst_globid AS stop_id,
  s.hst_name AS stop_long_name,
  s.hst_name AS locality,
  s.hst_name AS stop_name_without_locality,
  '' AS assumed_platform,
  1 number_of_station_quays,
  '' parent,
  s.hst_y AS latitude,
  s.hst_x AS longitude,
  '' "mode",
  linien_agg AS route_short_names,
  ST_TRANSFORM(ST_POINT(hst_y, hst_x), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM "at".haltestellen AS s
WHERE hst_id NOT IN (select hst_id from "at".steige);

