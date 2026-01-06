# How to adapt this project for other countries

While this project currently focuses on German stop data,
it may be adapted to other countries' stop data.
Note: due to currently hardcoded projection to `EPSG:25832`, the following guidelines only apply to European countries. 
For usage in other regions, all references to `EPSG:25832` need to be extracted and made configurable.
Note further, that report generation and dashboard currently only work for German stop data as they expect specific IFOPT structure (DHID) for stop IDs.
However, if you plan to adapt this project for other regions, get in touch. PRs are welcome!

1. Create an `.env_<countrycode>` file and provide download links for GTFS, stops and OSM data. 
2. Change COUNTRY var to `countrycode`  in Makefile
3. Create seeds/models/`<countrycode>`/transit_stops.sql. The model must provide the following columns:

Column name | Type | Description
------------|------|------------
stop_id | TEXT | Stop id of the stop, should be the same as used in the GTFS stops.txt
stop_name | TEXT | Stop name
locality | TEXT | Locality
stop_name_without_locality | TEXT | Stop name without locality
assumed_platform | TEXT | platform code
number_of_station_quays | INT |
parent | TEXT | ID of parent station, if any
stop_lat | DOUBLE | latitude (WGS84)
stop_lon | DOUBLE | longitude (WGS84)
mode | TEXT | primary mode served at this stop as used in OpenStreetMap. The GTFS route types map as follows: 0: `tram`, 1: `light_rail`, 2:`train`, 3: `bus`, 4: `ferry`, 7: `funicular`, or NULL if multiple.
route_short_names|TEXT| route short names, comma separated
projected_geometry|GEOMETRY| Stop coordinate as geometry, currently projected to EPSG:25832.


