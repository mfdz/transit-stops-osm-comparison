HOST_MOUNT = $(shell set +e; if [ -n "$$HOST_MOUNT" ]; then echo "$$HOST_MOUNT"; else echo "$$PWD"; fi)
TOOL_CFG = /cfg
TOOL_DATA = /seeds

PYOSMIUM_IMAGE=mfdz/pyosmium

# Shortcuts for the (dockerized) transform/merge tools.
OSMIUM_UPDATE = docker run -i --rm -v $(HOST_MOUNT)/seeds:$(TOOL_DATA) $(PYOSMIUM_IMAGE) pyosmium-up-to-date

# Read environment variable files, in case they exist
-include .env .env.local


.PHONY: download, plan-no-backfill, plan-restate

download: seeds/gtfs.zip seeds/zhv.zip
	# Download/Update OSM extracts from Geofabrik
	OSMIUM_UPDATE="$(OSMIUM_UPDATE) $(TOOL_DATA)/data.osm.pbf" ./scripts/update_osm.sh '$(OSM_DOWNLOAD_URL)' 'seeds/data.osm.pbf'
	
seeds/gtfs.zip: FORCE
	# Download GTFS data (we expect, that often files are not yet available and 404s occur, so we ignore errors with || true)
	./scripts/download.sh $(GTFS_DOWNLOAD_URL) seeds/gtfs.zip || true

seeds/zhv.zip: FORCE
	# Download zHV data (we expect, that often files are not yet available and 404s occur, so we ignore errors with || true)
	./scripts/download.sh $(STOP_REGISTRY_DOWNLOAD_URL) seeds/zhv.zip || true

plan-no-backfill:
	sqlmesh plan --auto-apply --skip-backfill --no-gaps

plan-restate:
	sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*'

.last_run: download
	# TODO sqlmesh run
	sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*'
	touch .last_run

out/index.html: .last_run
	# TODO generiere
	mkdir -p out
	touch out/index.html

FORCE:
