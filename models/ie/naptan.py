import pandas as pd
import typing as t
from sqlmesh import ExecutionContext, model
from datetime import datetime
import json

@model(
    "ie.naptan",
    kind="FULL",
    columns = {
        'AtcoCode': "text",
        'Longitude': 'double',
        'Latitude': 'double',
        'ShortCommonName': "text",
        'ShortCommonNameGA': "text",
        'Status': "text",
        'CommonName': "text",
        "CommonNameGA": "text",
        "Street": "text",   
    }
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    with open('seeds/ie/naptan.json') as f:
        # fieldnames = ['CommonNameGA', 'Longitude', 'Status', 'Easting', 'Latitude', 'AtcoCode', 'ShortCommonName', 'AdministrativeAreaRef', 'ModificationDateTime', 'CompassPoint', 'BusStopType', 'NptgLocalityRef', 'CreationDateTime', 'TimingStatus', 'StopType', 'Northing', 'ShortCommonNameGA', 'CommonName', 'Street','PlateCode','StopAreaRef']
        j = json.load(f)
        stops = [feature['properties'] for feature in j['features']]
        yield pd.DataFrame(stops)
