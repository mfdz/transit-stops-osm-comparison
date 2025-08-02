MODEL (
  name stage.osm_stop_candidates_with_mode_and_type,
  kind VIEW
);

SELECT
  c.* EXCLUDE (ref, local_ref, ref_ifopt, ref_pt_id),
  COALESCE(ref_ifopt, ref_pt_id) ref,
  CASE 
    WHEN NOT ref_ifopt IS NULL THEN 'ref:IFOPT'
    WHEN NOT ref_pt_id IS NULL THEN 'ref:pt_id'
    ELSE NULL
  END ref_key,
  CASE
    WHEN bus = TRUE
    THEN CASE WHEN train OR tram OR light_rail OR ferry OR funicular THEN NULL ELSE 'bus' END
    ELSE CASE
      WHEN train AND NOT (
        tram OR light_rail
      )
      THEN 'train'
      WHEN tram AND NOT (
        train OR light_rail
      )
      THEN 'tram'
      WHEN light_rail AND NOT (
        train OR tram
      )
      THEN 'light_rail'
      WHEN train OR tram OR light_rail
      THEN 'trainish'
      WHEN ferry
      THEN 'ferry'
      WHEN funicular
      THEN 'funicular'
      WHEN highway = 'bus_stop'
      THEN 'bus'
      WHEN NOT railway IS NULL
      THEN 'trainish'
      ELSE NULL
    END
  END AS mode,
  CASE
    WHEN public_transport='station'
    THEN 'station'
    WHEN railway IN ('stop','tram_stop') OR public_transport='stop_position'
    THEN 'stop'
    WHEN highway ='bus_stop' OR public_transport='platform'
    THEN 'platform'
    WHEN railway ='halt'
    THEN 'halt'
    ELSE NULL
  END "type",
  CASE
    WHEN LENGTH(ref) < 3
    THEN ref
    WHEN LENGTH(local_ref) < 3
    THEN local_ref
    ELSE REGEXP_EXTRACT(name, ' (\d+$)', 1)
  END AS assumed_platform
FROM stage.osm_stop_candidates c