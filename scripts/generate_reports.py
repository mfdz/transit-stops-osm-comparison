import datetime
import logging
import duckdb
import pandas as pd
import argparse
import json
from pathlib import Path
from html_reports import Report

logger = logging.getLogger('StopsPerDistricLister')

REGIONS_TEMPLATE="templates/region.html"

def add_html(self, html_fragment):
    """ Adds a title """

    self.body.append(html_fragment)

Report.add_html = add_html

class StopsPerDistricLister():
    FETCH_SIZE = 50

    METADATA_QUERY = """
        SELECT key, value FROM matching.match_meta_data
        """

    MATCH_STATE_PER_REGION_QUERY = """
        SELECT * FROM result.match_state_per_region
        """

    STOPS_PER_REGION = """
        SELECT locality "Ortsteil", stop_name_without_locality "Haltestelle", h.stop_id "globaleID", h.latitude lat, h.longitude lon, h.mode, h.match_state, o.osm_id,
          round(h.distance,1) distance, round(h.rating,2) rating,
          o.name "osm_name", routes, official_direction, osm_direction,
          CASE WHEN o.osm_id IS NULL THEN 'POINT('||h.longitude||' '||h.latitude||')' ELSE 'LINESTRING('||h.longitude||' '||h.latitude||','||o.lon||' '||o.lat||')' END WKT
        FROM result.matches h
        LEFT JOIN stage.osm_stops o ON o.osm_id = h.osm_id
        WHERE stop_id LIKE ?
        OR h.parent LIKE ?
        ORDER BY ortsteil,haltestelle, h.stop_id;
        """

    DISTRICTS_QUERY = """
        SELECT 'de:'||ags district, bez, gen FROM de.vg250_krs WHERE gf=4
        """

    def __init__(self, connection):
        self.db = connection

    def _rows(self, sql, params = []):
        cur = self.db.execute(sql, params)
        columns = [desc[0] for desc in cur.description]

        while True:
            rows = cur.fetchall()
            if len(rows) == 0:
                return

            for row in rows:
                yield dict(zip(columns, row))

    def as_html_table(self, headers, rows_as_html):
        """ Adds the list of dicts as table """
        table_html = """
            <table class="sortable">
                <thead>
                    {header_cols}
                </thead>
                <tbody>
                    {rows_html}
                </tbody>
            </table>
        """
        header_cols = ''
        for header in headers:
            header_cols += ('<th>'+header+'</th>')
        rows_html =''
        for row in rows_as_html:
            rows_html += '<tr>'
            rows_html += row
            rows_html += '</tr>'

        return table_html.format(header_cols=header_cols, rows_html=rows_html)

    def render_overview(self, outdir, metadata):
        df = pd.read_sql_query(self.MATCH_STATE_PER_REGION_QUERY,self.db)
        df = df.pivot_table(index='region',columns=['match_state'],values='count', fill_value=0, aggfunc='sum')
        df['Gesamt'] = df['MATCHED'] +  df['MATCHED_AMBIGUOUSLY'] + df['MATCHED_THOUGH_DISTANT']+ df['MATCHED_THOUGH_NAMES_DIFFER']+ df['MATCHED_THOUGH_OSM_NO_NAME']+ df['MATCHED_THOUGH_REVERSED_DIR'] + df['NO_MATCH']+ df['NO_MATCH_BUT_OTHER_PLATFORM_MATCHED']+ df['NO_MATCH_AND_SEEMS_UNSERVED']
        districts = pd.DataFrame.from_dict(self.districts, orient='index')
        df = df.join(districts)
        df.reset_index(inplace=True)
        table_html = df.to_html( escape=False,
            classes='sortable',
            index=False,
            columns= ['region', 'GEN', 'MATCHED',
                      'MATCHED_AMBIGUOUSLY',
                      'MATCHED_THOUGH_DISTANT',
                      'MATCHED_THOUGH_NAMES_DIFFER',
                      'MATCHED_THOUGH_OSM_NO_NAME',
                      'MATCHED_THOUGH_REVERSED_DIR',
                      'NO_MATCH',
                      'NO_MATCH_BUT_OTHER_PLATFORM_MATCHED',
                      'NO_MATCH_AND_SEEMS_UNSERVED',
                      'Gesamt'],
            formatters={'region': lambda x: '<a href="region_'+x.replace(':','')+'.html">'+x+'</a>'})
        rep = Report()

        rep.add_title("DELFI-Haltestellen-OSM-Vergleich")
        rep.add_html("""
            <p>Die nachfolgenden Tabelle listet das kreisweise Ergebnis eines Abgleichs des
            zentralen Haltestellen-Verzeichnisses (zHV) des DELFI e.V. mit den Haltestellen-Informationen
            aus OpenStreetMap.</p>

            <p>Diese Auswertung wird in der Regel wöchentlich nach Veröffentlichung aktueller DELFI zHV und GTFS-Daten aktualisiert.</p>

            <p>Beachten Sie, dass weder die offiziellen Daten, noch die OpenStreetMap-Daten, noch das von uns
            durchgeführte Matching fehlerfrei sind. Gelistet werden hier nur die von uns ermittelten Inkosistenzen.
            Welche Information korrekt ist, oder ob vielleicht die Zuordnung fehlerhaft ist, muss in jedem
            Einzelfall geprüft werden. Alle Angaben ohne Gewähr.</p>

            <p>Details zum Vorgehen beschreibt dieser <a href='https://www.mfdz.de/blog/haltestellendaten-bw-vergleich-osm-nvbw'>Blog-Beitrag</a>,
            der Code ist auf <a href='https://github.com/mfdz/transit-stops-osm-comparison'>Github</a> verfügbar.
            Mutmaßliche Fehler oder Verbesserungsvorschläge zum Abgleich-Verfahren können dort gemeldet bzw.
            (noch besser) per Pull-Request vorgeschlagen werden. Systematische Fehler des zHV-Datensatzes
            tragen wir im GitHub-Repository <a href='https://github.com/mfdz/zhv-issues/issues'>zhv-issues</a> zusammen.</p>

            <p>Die verschiedenen Abgleich-Status und mögliche Ursache sowie Behebungs-Optionen beschreiben wir in dieser <a href='https://github.com/mfdz/transit-stops-osm-comparison/blob/master/docs/faq.de.md'>FAQ</a>.
            """)
        rep.add_title("Versionen", level=2)
        rep.add_html(self.version_fragment(metadata))
        rep.add_html(table_html)
        rep.write_report(template_path=REGIONS_TEMPLATE, filename=outdir+"/index.html")

        df.to_csv(outdir+'/overview.csv', sep='\t', encoding='utf-8')

    def osm_match_link(self, osmid):
        if osmid:
            feature = osmid.replace('w','way=').replace('n','node=').replace('r','relation=')
            return '<a href="https://www.openstreetmap.org/?{}" target="_blank" rel="noopener noreferrer">{}</a>'.format(feature, osmid)
        else:
            return ''

    def lat_lon_link(self, lat, lon):
        if lat:
            return '<a href="https://www.openstreetmap.org/?mlat={}&mlon={}#map=17/{}/{}&layers=ON" target="_blank" rel="noopener noreferrer">{},<nbsp/>{}</a>'.format(lat, lon, lat, lon, lat, lon)
        else:
            return ''

    def fromtimestampstr(self, ts_str):
        return datetime.datetime.fromtimestamp(float(ts_str)).strftime("%Y-%m-%d %H:%M:%S")

    def version_fragment(self, metadata):
        return '''<ul>
                    <li>OSM-Daten: {osm_date}, © <a href="https://osm.org">OpenStreetMap</a> Mitwirkende, via <a href="https://www.geofabrik.de/">Geofabrik</a> (Thanks!) </li>
                    <li>GTFS-Daten: {gtfs_date}, © <a href="https://www.delfi.de/">DELFI e.V.</a></li>
                    <li>Haltestellen-Register: {stops_date}, © <a href="https://www.delfi.de/">DELFI e.V.</a></li>
                    <li>Verwaltungsgrenzen: © Geobasis-DE / BKG 2022</li>
                    <li>Abgleich: {match_date}</li>
                 </ul>

                 <p>Nähere Erläuterungen zu den Abgleich-Status finden sie in den <a href='https://github.com/mfdz/transit-stops-osm-comparison/blob/main/docs/faq.de.md'>FAQs</a></p>
                    '''.format(
                            osm_date=self.fromtimestampstr(metadata['osm_timestamp']),
                            gtfs_date=self.fromtimestampstr(metadata['gtfs_timestamp']),
                            stops_date=self.fromtimestampstr(metadata['stops_timestamp']),
                            match_date=self.fromtimestampstr(metadata['match_timestamp']),
                            )

    def render_stops_of_station(self, rows_html, rows_per_station, last_city, last_station):
        station_html = """<td rowspan='{count}'>{Ortsteil}</td>
                        <td rowspan='{count}'>{Haltestelle}</td>
                        """.format(count = len(rows_per_station),
                               Ortsteil = last_city,
                               Haltestelle = last_station)
        rows_html.append(station_html + rows_per_station[0])
        rows_html.extend(rows_per_station[1:])

    def query(self, sql, params):
        return self.db.sql(sql, params=params).df()

    def render_region_as_csv(self, region, outdir):
        df = self.query(self.STOPS_PER_REGION, params=[region+"%", region+"%"])
        if df is None:
            print(f"No stops for region {region}")
            return
        df.to_csv(outdir+'/region_'+region.replace(':','')+'.csv', sep='\t', encoding='utf-8')

    def render_region(self, region, outdir, metadata):
        self.render_region_as_csv(region, outdir)
        headers = ['Ortsteil', 'Haltestelle', 'Name (OSM)', 'DHID', 'Koordinaten','Mode','Abgleich-Status','Link zu gematchem Halt','Entfernung','Bewertung', 'Linien','Folgehalt (offiziell)', 'Folgehalt (OSM)']
        rows_html = []
        rows_per_station = []
        last_city = ''
        last_station = ''
        for stop in self._rows(self.STOPS_PER_REGION, [region+"%", region+"%"]):
            if last_city != stop['Ortsteil'] or last_station != stop['Haltestelle']:
                if last_city != '' or last_station != '':
                    self.render_stops_of_station(rows_html, rows_per_station, last_city, last_station)
                    rows_per_station=[]

                last_city = stop['Ortsteil']
                last_station = stop['Haltestelle']

            stop['osm_link'] = self.osm_match_link(stop['osm_id'])
            stop['lat_lon_link'] = self.lat_lon_link(stop['lat'], stop['lon'])

            stop_html = """<td>{osm_name}</td>
            <td>{globaleID}</td>
            <td>{lat_lon_link}</td>
            <td>{mode}</td>
            <td class="{match_state}">{match_state}</td>
            <td>{osm_link}</td>
            <td>{distance}</td>
            <td>{rating}</td>
            <td>{routes}</td>
            <td>{official_direction}</td>
            <td>{osm_direction}</td>
            """.format(**stop)
            stop_html = stop_html.replace('>None</td>', '></td>')
            rows_per_station.append(stop_html)

        self.render_stops_of_station(rows_html, rows_per_station, last_city, last_station)

        table_html = self.as_html_table(headers, rows_html)

        rep = Report()
        district = self.districts.get(region)
        rep.add_title("Haltestellenabgleich DELFI - OSM Landkreis {ags} - {district}".format(ags=region[3:],
                            district=district['GEN'] if district else 'Unbekannt'))

        rep.add_title("Versionen", level=2)
        rep.add_html(self.version_fragment(metadata))
        rep.add_html('<p>Alternative Ansicht: <a href="region_'+region.replace(':','')+'.csv">CSV</a>')
        rep.add_html('<p><small><em>Hinweis: Durch Klick auf eine Spaltenüberschrift lässt sich die Tabelle sortieren. Beim ersten Sortieren wird die Gruppierung zusammengehöriger Haltepunkte aufgelöst, damit alle Zeilen korrekt sortiert werden können.</em></small></p>')
        rep.add_html(table_html)

        filename = outdir+'/region_{region}.html'.format(region=region.replace(':',''))
        rep.write_report(template_path=REGIONS_TEMPLATE, filename=filename, prettify=False)
        print("Wrote", region[3:])

    def load_districts(self):
        self.districts = {r['district']: r for r in self._rows(self.DISTRICTS_QUERY)}

    def load_metadata(self):
        metadata = {}
        for row in self._rows(self.METADATA_QUERY):
            metadata[row['key']] = row['value']

        return metadata

    def render(self, outdir):
        metadata = self.load_metadata()
        self.load_districts()
        Path(outdir).mkdir(parents=True, exist_ok=True)

        # Copy JavaScript and CSS files to output directory
        import shutil
        templates_dir = Path(__file__).parent.parent / 'templates'
        js_source = templates_dir / 'sortable-table.js'
        css_source = templates_dir / 'table-styles.css'
        shutil.copy(js_source, Path(outdir) / 'sortable-table.js')
        shutil.copy(css_source, Path(outdir) / 'table-styles.css')

        self.render_overview(outdir, metadata)
        for district in self.districts:
            self.render_region(district, outdir, metadata)

def dict_factory(cursor, row):
     col_names = [col[0] for col in cursor.description]
     return {key: value for key, value in zip(col_names, row)}

def open_duckdb_db(duckdb_path):
    db = duckdb.connect(duckdb_path, read_only = True)
    return db

def main(database_path, outdir):
    db = open_duckdb_db(database_path)
    renderer = StopsPerDistricLister(db)
    renderer.render(outdir)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', dest='db', required=False, help='Database file', default='db_de.db')
    parser.add_argument('-o', dest='outdir', required=False, help='Output directory', default='out/reports')
    args = parser.parse_args()

    exit(main(args.db, args.outdir))
