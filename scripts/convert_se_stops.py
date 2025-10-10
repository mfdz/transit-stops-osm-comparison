from lxml import etree
import csv
import argparse



ns={
    'ns4': 'http://www.samtrafiken.se/netex',
    'ns2': 'http://www.opengis.net/gml/3.2',
    'ns3': 'http://www.siri.org.uk/siri',
    '': 'http://www.netex.org.uk/netex'
}

def keyvalues_as_dict(elem):
    return { kv.findtext('Key', namespaces=ns): kv.findtext('Value', namespaces=ns) for kv in elem}

def convert(data_dir, feed):
    file=f'{data_dir}/_stops.xml'
    stops_csv_file=f'{data_dir}/stops.csv'
    
    tree = etree.parse(file)
    root = tree.getroot()

    with open(stops_csv_file, 'w', newline='') as stops_csvfile:
        stops_csvwriter = csv.writer(stops_csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        stops_csvwriter.writerow(['stop_id', 'stop_name', 'stop_lat', 'stop_lon', 'parent_station', 'platform_code', 'rikshallplats'])
                
                    
        stopPlaces = root.findall('dataObjects/SiteFrame/stopPlaces/StopPlace', ns)
        parent = ""
        for sp in stopPlaces:
            keyValues = keyvalues_as_dict(sp.findall('keyList/KeyValue', namespaces=ns))
            stop_id = sp.get('id')
            stop_name = sp.findtext('Name', namespaces=ns)
            stop_lat = sp.findtext('Centroid/Location/Latitude', namespaces=ns)
            stop_lon = sp.findtext('Centroid/Location/Longitude',  namespaces=ns)
            platform_code =""
            rikshallplats = keyValues.get('rikshallplats')
            quays = sp.findall('quays/Quay', namespaces=ns)
            
            # Don't write areas
            if not '_' in stop_id:
                parent = stop_id
                stops_csvwriter.writerow([stop_id, stop_name, stop_lat, stop_lon, "", platform_code, rikshallplats])

            for q in quays:
                keyValues = keyvalues_as_dict(q.findall('keyList/KeyValue', namespaces=ns))
                quay_stop_id = q.get('id')
                stop_name = q.findtext('Name', namespaces=ns)
                stop_lat = q.findtext('Centroid/Location/Latitude', namespaces=ns)
                stop_lon = q.findtext('Centroid/Location/Longitude',  namespaces=ns)
                platform_code = q.findtext('PublicCode', namespaces=ns)
                
                stops_csvwriter.writerow([quay_stop_id, stop_name, stop_lat, stop_lon, parent, platform_code, ""])



parser = argparse.ArgumentParser(
    prog='convert',
    description='Convert SE NETeX Stops into csv')
parser.add_argument('--datadir', default='seeds')
parser.add_argument('feed')
args = parser.parse_args()
convert(args.datadir, args.feed)
