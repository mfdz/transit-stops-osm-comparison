HOST_MOUNT = $(shell set +e; if [ -n "$$HOST_MOUNT" ]; then echo "$$HOST_MOUNT"; else echo "$$PWD"; fi)
TOOL_CFG = /cfg
TOOL_DATA = /seeds

PYOSMIUM_IMAGE=mfdz/pyosmium

# Shortcuts for the (dockerized) transform/merge tools.
OSMIUM_UPDATE = docker run -i --rm -v $(HOST_MOUNT)/seeds:$(TOOL_DATA) $(PYOSMIUM_IMAGE) pyosmium-up-to-date

COUNTRY=de
# Read environment variable files, in case they exist
-include .env_$(COUNTRY) .env.local

OSM_PBF_FILE=seeds/$(COUNTRY)/data.osm.pbf
GTFS_FILE=seeds/$(COUNTRY)/gtfs.zip
STOPS_FILE=seeds/$(COUNTRY)/zhv.zip
SQLMESH_DOTENV_PATH=.env_$(COUNTRY)

.PHONY: download, plan-no-backfill, plan-restate


download:
	# Download GTFS data (we expect, that often files are not yet available and 404s occur, so we ignore errors with || true)
	./scripts/download.sh $(GTFS_DOWNLOAD_URL) $(GTFS_FILE) || true
	# Download stop data (we expect, that often files are not yet available and 404s occur, so we ignore errors with || true)
	./scripts/download.sh $(STOP_REGISTRY_DOWNLOAD_URL) $(STOPS_FILE) || true
	# Download/Update OSM extracts from Geofabrik
	@if [ $(GTFS_FILE) -nt $(OSM_PBF_FILE) ] && [ $(STOPS_FILE) -nt $(OSM_PBF_FILE) ]; then \
		OSMIUM_UPDATE="$(OSMIUM_UPDATE) $(TOOL_DATA)/$(COUNTRY)/data.osm.pbf" ./scripts/update_osm.sh '$(OSM_DOWNLOAD_URL)' '$(OSM_PBF_FILE)'; \
	else \
		echo "Don't update OSM as at least one of GTFS or stops file is older than pbf" ; \
		false ; \
	fi
	
db_$(COUNTRY).db:
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh plan --auto-apply

plan-no-backfill:
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh plan --auto-apply --skip-backfill --no-gaps

plan-restate:
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*' -r '$(COUNTRY).*' -r 'matching.match_meta_data'


compare: db_$(COUNTRY).db
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh run

.last_run: download
	# TODO sqlmesh run
	sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*'
	touch .last_run

out/index.html: .last_run
	# TODO generiere
	mkdir -p out
	touch out/index.html

