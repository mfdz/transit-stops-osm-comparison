HOST_MOUNT = $(shell set +e; if [ -n "$$HOST_MOUNT" ]; then echo "$$HOST_MOUNT"; else echo "$$PWD"; fi)
TOOL_CFG = /cfg
TOOL_DATA = /seeds

PYOSMIUM_IMAGE=mfdz/pyosmium

# Shortcuts for the (dockerized) transform/merge tools.
OSMIUM_UPDATE = docker run -i --rm -v $(HOST_MOUNT)/seeds:$(TOOL_DATA) $(PYOSMIUM_IMAGE) pyosmium-up-to-date

# Read environment variable files, in case they exist
-include .env .env.local

# Download/Update OSM extracts from Geofabrik
seeds/data.osm.pbf:
	$(info downloading/updating OSM extract)
	OSMIUM_UPDATE="$(OSMIUM_UPDATE) $(TOOL_DATA)/$(@F)" ./scripts/update_osm.sh '$(OSM_DOWNLOAD_URL)' '$@'

