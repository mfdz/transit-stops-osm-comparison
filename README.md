# Transit Stops OSM Comparison

Several countries publish official transit stop data. This data usually differs from crowd-sources OpenStreetMap stop data.

This project compares offical stop data against OpenStreetMap stop data.

You can see the results of the comparison for German transit stops at [haltestellen-osm-qs.de](https://haltestellen-osm-qs.de).

## Prerequisites

This project is bases on Tobiko Data's [SQLMesh](https://sqlmesh.readthedocs.io/), a data transformation framework. You'll need python and a couple of unix tools like make, curl etc.

For updating the OSM pbf file after the initial download, this project uses a dockerized version of pyosmium. So needs to be installed, also.

## Comparing DELFI zHV data against OSM
To compare the German DELFI zHV dataset against OSM, you'll need to download the zHV dataset, the DELFI GTFS dataset (which we use to derive preceding and subsequent stops and route types served at a stop) as well as the OSM dataset germany-latest.pbf from Geofabrik. Finally, a dataset providing names and codes of German districts needs to be downloaded from BKG as well.

To download these, a simple

```sh
$ make download
```

should be sufficient.

To compare the official data against OSM data, run `make compare`:

```sh
$ make compare
```

This will create the duckdb database (`db_de.db`) and perform the matching. This will, depending on you machine, take a couple of minutes.

## Generating issue reports

To create reports documenting the comparison results, you may run the `scripts/generate_reports.py` via

```sh
$ make generate-reports
```

It will render an overview index.html and for every district a detailed html report as well as a CSV file per district, which you can import e.g. in a GIS to do further analysis.

## Analysing stop data for other countries
While this project is currently focused on German stop data, it may be adapted to analyse other countries stop data. For details how to proceed, see [other_countries.md](docs/other_countries.md)

## Troubleshooting
In case of problems, the [troubleshooting guide](docs/troubleshooting.md) may be helpful, or, if you think you encountered an issue, please report it.
