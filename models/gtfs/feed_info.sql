MODEL (
  name gtfs.feed_info,
  kind FULL,
  columns (
    feed_publisher_name TEXT,
    feed_publisher_url TEXT,
    feed_lang TEXT,
    feed_version TEXT
  ),
  grain (
    feed_id
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/gtfs.zip/feed_info.txt', quote = '"')