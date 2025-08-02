#!/bin/bash
set -e

url="$1"
if [ -z "$url" ]; then 1>&2 echo 'missing 1st argument: url'; exit 1; fi
dest_file="$2"
if [ -z "$dest_file" ]; then 1>&2 echo 'missing 2nd argument: dest_file'; exit 1; fi


ua='User-Agent: transit-stops-osm-comparison'
etag_file="$dest_file.etag"

if test -e "$$dest_file"
then zflag="-z '$dest_file'"
else zflag=
fi

curl $zflag -Lf -H "$ua" --compressed -R "$url" '-o' "$dest_file"
