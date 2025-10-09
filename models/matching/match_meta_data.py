import pandas as pd
import typing as t
from sqlmesh import ExecutionContext, model
import time
from datetime import datetime
import os

@model(
    "matching.match_meta_data",
    columns={
        "key": "text",
        "value": "text",
    },
    cron='@weekly',
    kind="FULL"
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    folder = 'seeds'
    gtfs_timestamp = os.path.getmtime(f'{folder}/gtfs.zip')
    osm_timestamp = os.path.getmtime(f'{folder}/data.osm.pbf')
    stops_timestamp = os.path.getmtime(f'{folder}/zhv.zip')
    data = { 
      'key': ['match_timestamp', 'gtfs_timestamp', 'osm_timestamp','stops_timestamp'], 
      'value': [time.time(), gtfs_timestamp, osm_timestamp, stops_timestamp],
    }
    return pd.DataFrame.from_dict(data)
