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

.PHONY: download, plan-no-backfill, plan-restate, compare, generate-reports, preview-reports


# Download German district data for reporting
seeds/de/VG250_KRS.shp:
	mkdir -p seeds/de
	./scripts/download.sh https://daten.gdz.bkg.bund.de/produkte/vg/vg250_ebenen_1231/aktuell/vg250_12-31.utm32s.shape.ebenen.zip seeds/de/vg250_12-31.utm32s.shape.ebenen.zip
	unzip -d seeds/de -j seeds/de/vg250_12-31.utm32s.shape.ebenen.zip vg250_12-31.utm32s.shape.ebenen/vg250_ebenen_1231/VG250_KRS.*

download: seeds/de/VG250_KRS.shp
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
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*' -r '$(COUNTRY).*' -r 'matching.*' -r 'history.*'

compare: db_$(COUNTRY).db
	SQLMESH_DOTENV_PATH=.env_$(COUNTRY) sqlmesh run

.last_run: download
	# TODO sqlmesh run
	sqlmesh plan --auto-apply -r 'raw.*' -r 'gtfs.*'
	touch .last_run

generate-reports:
	python3 scripts/generate_reports.py

# Preview reports on GitHub Pages (for showcasing new features)
# Note: This is intended for contributors to demonstrate changes.
# Uses git worktree to avoid touching the main workspace.
preview-reports:
	@if [ ! -d "out/reports" ]; then \
		echo "Error: out/reports directory not found."; \
		echo "Run 'make generate-reports' first."; \
		exit 1; \
	fi
	@echo "Creating preview of reports on gh-pages branch..."
	@TEMP_DIR=$$(mktemp -d) && \
	git branch -D gh-pages 2>/dev/null || true && \
	git worktree add --orphan -b gh-pages "$$TEMP_DIR" >/dev/null 2>&1 && \
	cp -r out/reports/* "$$TEMP_DIR/" && \
	cd "$$TEMP_DIR" && git add . && git commit -m "Preview reports - $$(date +'%Y-%m-%d %H:%M')" --quiet && \
	cd - >/dev/null && git worktree remove "$$TEMP_DIR" && \
	echo "" && \
	echo "✓ Preview committed to gh-pages branch" && \
	echo "" && \
	echo "To publish preview, run:" && \
	echo "  git push -f origin gh-pages"
