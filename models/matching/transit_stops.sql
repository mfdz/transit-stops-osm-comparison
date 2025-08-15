MODEL (
  name matching.transit_stops,
  kind FULL,
  description "Quays and stations without quays, with a normalized name and quay name extracted (as best effort) from the quay's name. Coordinate is projected to UTM32 to allow RTREE indexing and fast distance calculations"
);

WITH quays AS (
  SELECT
    s.District,
    s.Municipality,
    s.Name,
    q.name AS quay_name,
    q.description,
    q.dhid,
    q.Latitude,
    q.Longitude,
    q.type,
    s.dhid AS parent
  FROM raw.zhv AS q
  JOIN raw.zhv AS a_or_s
    ON q.parent = a_or_s.dhid
  JOIN raw.zhv AS s
    ON a_or_s.parent = s.dhid AND s.type = 'S'
  WHERE
    q.type = 'Q'
), number_of_station_quays AS (
  SELECT
    parent,
    COUNT(*) AS cnt
  FROM quays
  GROUP BY
    parent
), stations_without_quays AS (
  SELECT
    s.District AS Landkreis,
    s.Municipality,
    s.Name,
    NULL AS quay_name,
    s.description,
    s.dhid,
    s.Latitude,
    s.Longitude,
    s.type,
    NULL AS parent
  FROM raw.zhv AS s
  WHERE
    s.type = 'S'
    AND NOT s.DHID IN (
      SELECT
        a_or_s.parent
      FROM raw.zhv AS q
      JOIN raw.zhv AS a_or_s
        ON q.parent = a_or_s.dhid
      WHERE
        q.type = 'Q'
    )
), route_short_names_per_stop_id AS (
  SELECT
    stop_id,
    LISTAGG(route_short_name, ',') AS route_short_names
  FROM stage.gtfs_stops_route_short_names
  GROUP BY
    stop_id
)
SELECT
  q.dhid AS globaleID,
  q.*
  EXCLUDE (dhid),
  COALESCE(e.expanded_name, q.name) AS stop_long_name,
  COALESCE(
    NULLIF(LTRIM(SUBSTRING(stop_long_name, 1, STRPOS(stop_long_name, ',') - 1)), ''),
    stop_long_name
  ) AS locality,
  LTRIM(SUBSTRING(stop_long_name, 1 + STRPOS(stop_long_name, ','))) AS stop_name_without_locality,
  COALESCE(
    NULLIF(REGEXP_EXTRACT(quay_name, '(Gleis |Bus |teig |Mast |^)([A-Z0-9].?)$', 2), ''),
    NULLIF(REGEXP_EXTRACT(quay_name, '^([A-Z0-9][A-Z0-9]?) ', 1), '')
  ) AS assumed_platform,
  n.cnt AS number_of_station_quays,
  CASE
    WHEN gst.route_type = 3
    THEN 'bus'
    WHEN gst.route_type = 2
    THEN 'rail'
    WHEN gst.route_type = 0
    THEN 'tram'
    WHEN gst.route_type = 1
    THEN 'light_rail'
    WHEN gst.route_type = 4
    THEN 'ferry'
    WHEN gst.route_type = 7
    THEN 'funicular'
    WHEN quay_name LIKE (
      '%Tram%'
    ) OR quay_name LIKE (
      '%Strab %'
    )
    THEN 'tram'
    WHEN quay_name LIKE (
      '%Gleis%'
    )
    THEN 'trainish'
    WHEN quay_name LIKE (
      '%Fähranleger%'
    )
    THEN 'ferry'
    WHEN quay_name LIKE (
      '%Bus %'
    )
    OR quay_name LIKE (
      '%Fernbus%'
    )
    OR quay_name LIKE (
      '%AST%'
    )
    OR quay_name LIKE (
      '%SEV%'
    )
    OR quay_name LIKE (
      '%Steig%'
    )
    THEN 'bus'
    ELSE NULL
  END AS mode,
  route_short_names,
  ST_TRANSFORM(ST_POINT(latitude, longitude), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM quays AS q
LEFT JOIN stage.zhv_expanded_names AS e
  ON q.parent = e.dhid
JOIN number_of_station_quays AS n
  USING (parent)
LEFT JOIN stage.gtfs_stop_types AS gst
  ON gst.stop_id = q.dhid
LEFT JOIN route_short_names_per_stop_id AS rsn
  ON rsn.stop_id = q.dhid
WHERE
  NOT (
    description IS NOT NULL
    AND (q.description LIKE '%Zugang%' AND route_short_names IS NULL
    OR description LIKE '%rsatz%')
  )
UNION ALL
SELECT
  s.dhid AS globaleID,
  s.*
  EXCLUDE (dhid),
  COALESCE(e.expanded_name, s.name) AS stop_long_name,
  COALESCE(
    NULLIF(LTRIM(SUBSTRING(stop_long_name, 1, STRPOS(stop_long_name, ',') - 1)), ''),
    stop_long_name
  ) AS locality,
  LTRIM(SUBSTRING(stop_long_name, 1 + STRPOS(stop_long_name, ','))) AS stop_name_without_locality,
  NULL AS assumed_platform,
  1 AS number_of_station_quays,
  CASE
    WHEN gst.route_type = 3 
    THEN 'bus'
    WHEN gst.route_type = 2
    THEN 'train'
    WHEN gst.route_type = 0
    THEN 'tram'
    WHEN gst.route_type = 1
    THEN 'light_rail'
    WHEN gst.route_type = 4
    THEN 'ferry'
    WHEN gst.route_type = 7
    THEN 'funicular'
    ELSE NULL
  END AS mode,
  route_short_names,
  ST_TRANSFORM(ST_POINT(latitude, longitude), 'EPSG:4326', 'EPSG:25832') AS projected_geometry
FROM stations_without_quays AS s
LEFT JOIN stage.zhv_expanded_names AS e
  ON s.dhid = e.dhid
LEFT JOIN route_short_names_per_stop_id AS rsn
  ON rsn.stop_id = s.dhid
LEFT JOIN stage.gtfs_stop_types AS gst
  ON gst.stop_id = s.dhid
