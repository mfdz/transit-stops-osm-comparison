MODEL (
  name matching.rating_similarity_successor_names,
  kind FULL
);

/* TODO: might need to remove locality, street suffix (asse) "-" and "," from names as we did in v1 */
WITH successor_name_tuples AS (
  SELECT
    c.globaleid,
    c.osm_id,
    GREATEST(
      MAX(JACCARD(NULLIF(t.short_successor_name, ''), o.successor_name)),
      MAX(JACCARD(t.long_successor_name, o.successor_name))
    ) AS similarity
  FROM matching.match_candidates AS c
  JOIN stage.gtfs_stops_successor_names AS t
    ON c.globaleid = t.stop_id
  JOIN stage.osm_stops_successor_name AS o
    USING (osm_ID)
  GROUP BY
    c.globaleid,
    c.osm_id
), predecessor_name_tuples AS (
  SELECT
    c.globaleid,
    c.osm_id,
    GREATEST(
      MAX(JACCARD(NULLIF(t.short_predecessor_name, ''), o.predecessor_name)),
      MAX(JACCARD(t.long_predecessor_name, o.predecessor_name))
    ) AS similarity
  FROM matching.match_candidates AS c
  JOIN stage.gtfs_stops_predecessor_names AS t
    ON c.globaleid = t.stop_id
  JOIN stage.osm_stops_predecessor_name AS o
    USING (osm_ID)
  GROUP BY
    c.globaleid,
    c.osm_id
), osm_predecessor_transit_successor_name_tuples AS (
  SELECT
    c.globaleid,
    c.osm_id,
    GREATEST(
      MAX(JACCARD(NULLIF(t.short_successor_name, ''), o.predecessor_name)),
      MAX(JACCARD(t.long_successor_name, o.predecessor_name))
    ) AS similarity
  FROM matching.match_candidates AS c
  JOIN stage.gtfs_stops_successor_names AS t
    ON c.globaleid = t.stop_id
  JOIN stage.osm_stops_predecessor_name AS o
    USING (osm_ID)
  GROUP BY
    c.globaleid,
    c.osm_id
), osm_successor_transit_predecessor_name_tuples AS (
  SELECT
    c.globaleid,
    c.osm_id,
    GREATEST(
      MAX(JACCARD(NULLIF(t.short_predecessor_name, ''), o.successor_name)),
      MAX(JACCARD(t.long_predecessor_name, o.successor_name))
    ) AS similarity
  FROM matching.match_candidates AS c
  JOIN stage.gtfs_stops_predecessor_names AS t
    ON c.globaleid = t.stop_id
  JOIN stage.osm_stops_successor_name AS o
    USING (osm_ID)
  GROUP BY
    c.globaleid,
    c.osm_id
)
SELECT
  c.globaleid,
  c.osm_id,
  s.similarity AS osm_succ_transit_succ_similarity,
  p.similarity AS osm_pred_transit_pred_similarity,
  opts.similarity AS osm_pred_transit_succ_similarity,
  tpos.similarity AS osm_succ_transit_pred_similarity,
  GREATEST(osm_succ_transit_succ_similarity, osm_pred_transit_pred_similarity, 0) AS max_stop_sequence_similarity,
  GREATEST(osm_pred_transit_succ_similarity, osm_succ_transit_pred_similarity, 0) AS max_inversed_direction_similarity,
  CASE
    WHEN max_stop_sequence_similarity > @MINIMUM_SUCCESSOR_SIMILARITY
    AND (
      max_stop_sequence_similarity - max_inversed_direction_similarity
    ) >= @MINIMUM_SUCCESSOR_PREDECESSOR_DISTANCE
    THEN 1.0
    WHEN max_inversed_direction_similarity > @MINIMUM_SUCCESSOR_SIMILARITY
    AND (
      max_inversed_direction_similarity - max_stop_sequence_similarity
    ) >= @MINIMUM_SUCCESSOR_PREDECESSOR_DISTANCE
    THEN -1.0
    ELSE 0.0
  END AS similarity_successors
FROM matching.match_candidates AS c
LEFT JOIN successor_name_tuples AS s
  ON c.globaleid = s.globaleid AND c.osm_id = s.osm_id
LEFT JOIN predecessor_name_tuples AS p
  ON c.globaleid = p.globaleid AND c.osm_id = p.osm_id
LEFT JOIN osm_predecessor_transit_successor_name_tuples AS opts
  ON c.globaleid = opts.globaleid AND c.osm_id = opts.osm_id
LEFT JOIN osm_successor_transit_predecessor_name_tuples AS tpos
  ON c.globaleid = tpos.globaleid AND c.osm_id = tpos.osm_id