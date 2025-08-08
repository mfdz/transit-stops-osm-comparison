MODEL (
  name stage.osm_platform_ways_with_centroid,
  kind VIEW
);

SELECT
  osm_id,
  CASE
    WHEN ST_GEOMETRYTYPE(geometry) = 'POLYGON'
    THEN ST_CENTROID(geometry)
    ELSE ST_LINEINTERPOLATEPOINT(geometry, 0.5)
  END AS geometry,
  CASE
    WHEN ST_GEOMETRYTYPE(geometry) = 'POLYGON'
    THEN ST_TRANSFORM(ST_CENTROID(geometry), 'EPSG:4326', 'EPSG:25832')
    ELSE ST_TRANSFORM(ST_LINEINTERPOLATEPOINT(geometry, 0.5), 'EPSG:4326', 'EPSG:25832')
  END AS projected_geometry
FROM (
  SELECT
    *
  FROM stage.osm_platform_ways_with_geom
);

/*

@if(
   @runtime_stage = 'creating',
   CREATE INDEX @resolve_template('ix_geom_@{table_name}') ON @this_model USING RTREE (projected_geometry);
);

*/