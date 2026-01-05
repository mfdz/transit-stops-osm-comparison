MODEL (
  name de.zhv,
  kind FULL,
  tags delfi,
  columns (
    SeqNo INT,
    Type TEXT,
    DHID TEXT,
    Parent TEXT,
    Name TEXT,
    Latitude DOUBLE,
    Longitude DOUBLE,
    MunicipalityCode TEXT,
    Municipality TEXT,
    DistrictCode TEXT,
    District TEXT,
    Description TEXT,
    Authority TEXT,
    DelfiName TEXT,
    THID TEXT,
    TariffProvider TEXT,
    LastOperationDate TEXT,
    SEV TEXT
  ),
  grain (
    DHID
  )
);

SELECT
  *
  EXCLUDE (latitude, longitude),
  REPLACE(latitude, ',', '.')::DOUBLE AS latitude,
  REPLACE(longitude, ',', '.')::DOUBLE AS longitude
FROM READ_CSV('zip://seeds/de/zhv.zip/zHV_aktuell_csv.*.csv', quote = '"', escape = '\')