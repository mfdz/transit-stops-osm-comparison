MODEL (
  name gtfs.feed_info,
  kind FULL,
  columns (
    feed_publisher_name TEXT,
    feed_publisher_url TEXT,
    feed_lang TEXT
  ),
  grain (
    feed_id
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/'||@TRANSIT_STOPS_SCHEMA||'/gtfs.zip/feed_info.txt', quote = '"')