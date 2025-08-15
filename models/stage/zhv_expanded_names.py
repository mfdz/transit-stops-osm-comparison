import typing as t
import re
import pandas as pd
from sqlmesh import ExecutionContext, model
from datetime import datetime
import sys

districts_with_locality_after_comma = [
    "de:03351",
    "de:05315",
    "de:05374",
    "de:05378",
    "de:05382",
    "de:07138",
    "de:10041",
    "de:10042",
    "de:10043",
    "de:10044",
    "de:10045",
    "de:10046",
]

stop_name_replacements = {
    'de:03102': {
        r'^SZ(-|, )': r"Salzgitter, ",
    },
    'de:03151': {
        r'^E\.-L\.,? (.+)$': r"Ehra-Lessien, \g<1>",
    },
    'de:03158': {
        r'WF': 'Wolfenbüttel', 
    },
    'de:03254': {
        r'/': r" ",
        r'LIMMER, SCHULE': 'Alfeld (Leine), Limmer Schule',
    },
    'de:03351': {
        r'\(Kr CE\)': '(Celle)',
        r'^\(Celle\), Scharnhorst Scharnhorst Scharnhorst (.+)': r'Scharnhorst, \g<1>',
        r'^\(Aller\), Winsen Winsen': 'Winsen (Aller), Winsen',
    },
    'de:05111': {
        r'D-(.+)$': r'Düsseldorf, \g<1>',
    },
    'de:05114': {
        r'KR,(.+)$': r'Krefeld,\g<1>',
    },
    'de:05116': {
        r'MG,(.+)$': r'Mönchengladbach,\g<1>',
    },
    'de:05158': {
        r'L\'feld': 'Langenfeld (Rhld.),',
        r'ME-': 'Mettmann, ',
        r'Vel.-': 'Velbert, ',
    },
    'de:05513': {
        r'^GE,': 'Gelsenkirchen,', 
    },
    'de:05558': {
        r'^LH(.+)$': r'Lüdinghausen\g<1>',
    },
    'de:05566': {
        r'^FMO,': 'Greven, FMO,', 
    },
    'de:05711': {
        r'^BI-(.+)$': r'Bielefeld, \g<1>',
    },
    'de:05754': {
        r'^HC-(.+)$': r'Herzebrock-Clarholz, \g<1>',
        r'^RW-Rheda': r'Rheda, ',
        r'^RW-Wiedenb\w+': r'Wiedenbrück',
        r'^S\.H-': 'Schloß Holte-Stukenbrock, ',
    },
    'de:05762': {
        r'^B\.D(.+)$': r"Bad Driburg,\g<1>",
        r'^S-Sw,': 'Schieder-Schwalenberg,', 
    },
    'de:05766': {
        r'^B\.S\.?-(.+)$': r"Bad Salzuflen, \g<1>",
        r'^B.M-': 'Bad Meinberg, ',
        r'^S-Sw-Schieder,': 'Schieder,',
        r'^S-Sw-?Schwalenberg,': 'Schwalenberg,',
        r'^S-Sw-': 'Schieder-Schwalenberg, ',
        r'^H-BM-Horn': 'Horn, ',
    },
    'de:05770': {
        r'^B\.O-(.+)$': r'Bad Oeynhausen, \g<1>',
        r'^PW-': 'Porta Westfalica, ',
        r'P.O-': 'Preußisch Oldendorf, ',
    },
    'de:05774': {
        r'^B\.?W\.?-(.+)$': r"Bad Wünnenberg, \g<1>",
        r'^PB-': r"Paderborn, ",
    },
    'de:05913': {
        r'^DO,(.+)$': r'Dortmund,\g<1>',
    },
    'de:05962': {
        r'^AL': 'Altena', 
        r'N\'rade': 'Neuenrade', 
    },
    'de:06431': {
        r'^N-Liebers.*, (.+)': r'Nieder-Liebersbach \g<1>',
        r'U-Flockenbach.*, (.+)': r'Unter-Flockenbach \g<1>',
        r'^U-Schönmattenwag': 'Unter-Schönmattenwag',
        r'^W\.-Michelbach': 'Wald-Michelbach',
        r'^O.-Abtsteinach': 'Ober-Abtsteinach',
    },
    'de:07133': {
        r'^KH(.+)$': r'Bad Kreuznach\g<1>',
        r'^B\. Kreuz\.': 'Bad Kreuznach',
    },
    'de:07138': {
        r'\(Wied\), (.+),Asbach Asbach$': r'Asbach, \g<1>',
        r'^\(Wied\), (.+),Asbach (.+)$': r'Asbach, \g<2>, \g<1>',
        r'^\(Wied\)': r'Asbach',
    },
    'de:07312': {
        r'^K.lautern, ?(.+)$': r"Kaiserslautern, \g<1>",
    },
    'de:07314': {
        r'^BASF, (.+)$': r"Ludwigshafen am Rhein, BASF \g<1>",
        r'^LU(-| )': r"Ludwigshafen am Rhein, ",
    },
    'de:07339': {
        r'^B\'brück': 'Bingenerbrück', 
    },
    'de:08225': {
        r'^MOS (.+)$': r'Mosbach, \g<1>',
    },
    'de:08115': {
        r'^(Sifi |Sindelf\. ?)(.+)$': r"Sindelfingen, \g<2>",
        r'^(Sifi\. MB Hst\.) ?(.+)$': r"Sindelfingen, Mercedes-Benz Hst. \g<2>",
        r'^(Sifi\.? )(.+)$': r"Sindelfingen, \g<2>",
        r'^(Weil i.* S.) (.+)$': r"Weil im Schönbuch, \g<2>",
        r'^(W.* d.* S.*) (.+)$': r"Weil der Stadt \g<2>",
        r'^(Böbl\. ?)(.+)$': r"Böblingen, \g<2>",
        r'^(Leon\. ?)(.+)$': r"Leonberg, \g<2>",
        r'^BB': 'Böblingen,',
    },
    'de:08121': {
        r'^HN,? ': "Heilbronn, ",
        r'Böll\. Höfe': 'Böllinger Höfe',
    },
    'de:08136': {
        r'^GD( |, |-)(.+)$': r"Schwäbisch Gmünd, \g<2>",
        r'A\'felden(-|, )': 'Adelmannsfelden, ',
    },
    'de:08125': {
        r'^N\'sulm,(.+)': r'Neckarsulm,\g<1>',
        r'^NSU,(.+)': r'Neckarsulm,\g<1>',
    },
    'de:08221': {
        r'^HD,(.+)$': r"Heidelberg,\g<1>",
    },
    'de:08222': {
        r'^MA[ ,-](.+)$': r"Mannheim, \g<1>",
    },
    'de:08435': {
        r'^UM (.+)$': r"Uhldingen-Mühlhofen, \g<1>",
        r'^FN( |-|, )': r"Friedrichshafen, ",
        r'^SA[ -](.+)$': r"Salem, \g<1>",
        r'^ÜB[ -](.+)$': r"Überlingen, \g<1>",
        r'^TT[ -](.+)$': r"Tettnang, \g<1>",
        r'^D.tal': 'Deggenhausertal',
    },
    'de:08436': {
        r'^BW[, -](.+)$': r"Bad Waldsee, \g<1>",
        r'^RV[, -](.+)$': r"Ravensburg, \g<1>",
    },
    'de:08437': {
        r'^Herdw\.-Schön\.-': "Herdwangen-Schönach, ",
        r'Herdw\.-Schönach-': 'Herdwangen-Schönach, ',
    },
    'de:09175': {
        r'^M\. Schwaben,(.+)$': r'Markt Schwaben,\g<1>',
    },
    'de:09162': {
        r'^MAN, (.+)$': r"MAN \g<1>",
    },
    'de:09189': {
        r'^(RVO )?TS,?': 'Traunstein, ', 
    },
    'de:09661': {
        r'^AB-(.+)$': r"Aschaffenburg, \g<1>",
    },
    'de:09671': {
        r'^AB-(.+)$': r"Aschaffenburg, \g<1>",
    },
    'de:09676': {
        r'^AB-(.+)$': r"Aschaffenburg, \g<1>",
    },
    'de:09179': {
        r'^FFB(-| |, ?)(.+)$': r"Fürstenfeldbruck, \g<2>",
    },
    'de:09278': {
        r'^MAL-Pfaffenberg, (.+)$': r"Mallersdorf-Pfaffenberg, \g<1>",
    },
    'de:09377': {
        'MItterteich': 'Mitterteich'
    },
    'de:09186': {
        r'^PAF,(.*)$': r'Pfaffenhofen a.d. Ilm,\g<1>',
    },
    'de:10041': {
        r'^Kleinbli.*,(.+)$': r"Kleinblittersdorf,\g<1>",
        r'\(SCN\), Saarbrücken Ensheim Flughafen': 'Saarbrücken, Ensheim, Flughafen SCN',
    },
    'de:03101': {
        r'^BS, (.+)$': r"Braunschweig, \g<1>",
    },
    'de:12072': {
        r'VERWAIST: ': ''
    },
    'de:14524':
    { 
        r'^WDA,(.+)$': r'Werdau,\g<1>',
    },
    'de:14521': {
        r'^KO Oberwiesenthal, (.+)': r'Kurort Oberwiesenthal, \g<1>',
    },
    'de': {
        r'Bf$': r"Bahnhof",
        r'^St\. ?': r"Sankt ",
        r'\.': '. ',
        r'\,$':'',
        ',': ', ',
        '  ':' ',
        '. ,':'.,',
    },
}

def revert_comma_separated_parts(name):
    parts = name.split(',', 1)
    if len(parts)>1:
        municipality_settlement = parts[1].strip().split(' ')
        if len(municipality_settlement)>1:
            return f'{municipality_settlement[-1]}, {" ".join(municipality_settlement[:-1])} {parts[0]}'
        return f'{parts[1].strip()}, {parts[0]}'
    else:
        return name

def normalize_municipality(municipality):
    parts = municipality.split(' ')
    if len(parts)>2:
        city = parts[0]
        preposition = parts[1:-1]
        location = parts[-1]

        abbreviated_name = f'{city} ({location[0]})'
        return abbreviated_name
    return municipality

def extract_district(dhid):
    return ":".join(dhid.split(":", 2)[:2])

def remove_parentheses_at_start(name):
    no_params = re.sub(r'^ ?\(.*\) ?(.+)$', r'\g<1>', name)
    no_hyphen = re.sub(r'^-(.*$)', r'\g<1>', no_params)
    return no_hyphen

def apply_replacements(district, replaced_name):
    for regex_search_term, regex_replacement in stop_name_replacements[district].items():
        replaced_name = re.sub(regex_search_term, regex_replacement, replaced_name)
    return replaced_name

def chars_in_word(abbr, word):
    min_index = 0
    for char in abbr:
        if '.' == char:
            continue
        pos = word.find(char, min_index)
        if pos == -1:
            return False
        min_index = pos + 1
    return True

def extract_stop_name(original_name, municipality, dhid):
    original_name = original_name.strip()
    normalized_municipality = normalize_municipality(municipality)
    municipality_first_word = normalized_municipality.replace('/',' ').split(' ')[0]
    district = extract_district(dhid)
    
    replaced_name = revert_comma_separated_parts(original_name) if district in districts_with_locality_after_comma else original_name
    replaced_name = apply_replacements('de', replaced_name)
    if district in stop_name_replacements:
        replaced_name = apply_replacements(district, replaced_name)

    name_first_word = replaced_name.split(' ')[0]
    if not ' ' in municipality and '.' in name_first_word and municipality.startswith(name_first_word[:name_first_word.index('.')]):
        # stop_name has abbreviated first word which starts like municipality
        stop_name = " ".join(replaced_name.split(" ")[1:])
        return f'{municipality}, {remove_parentheses_at_start(stop_name).strip()}'
    if replaced_name==municipality:
        return replaced_name
    if ',' in replaced_name:
        hyphen_splitted = replaced_name.split('-', 1)
        if len(hyphen_splitted) > 1 and len(hyphen_splitted[0]) < 4:
            # handle abbreviated municipality
            if chars_in_word(hyphen_splitted[0], municipality):
                return f'{municipality}, {hyphen_splitted[1]}'
        comma_splitted = replaced_name.split(',', 1)
        if municipality.startswith(comma_splitted[0]) and comma_splitted[0][-1].isupper():
            return f'{municipality}, {comma_splitted[1].strip()}'        
        return replaced_name
    if replaced_name.startswith(municipality):
        stop_name = replaced_name[len(municipality):]
        stop_name = stop_name if len(stop_name) > 0 else original_name
        return f'{municipality}, {remove_parentheses_at_start(stop_name).strip()}'
    if replaced_name.startswith(normalized_municipality):
        stop_name = replaced_name[len(normalized_municipality)+1:]
        stop_name = stop_name if len(stop_name) > 0 else original_name
        return f'{municipality}, {stop_name}'
    if municipality_first_word not in ('Bad', 'Sankt') and replaced_name.startswith(municipality_first_word):
        stop_name = replaced_name[len(municipality_first_word):]
        stop_name = stop_name if len(stop_name) > 0 else original_name
        return f'{municipality}, {remove_parentheses_at_start(stop_name).strip()}'
    if not replaced_name.startswith(municipality):
        return f'{municipality}, {replaced_name}'

    return replaced_name

@model(
    "stage.zhv_expanded_names",
    columns={
        "dhid": "text",
        "expanded_name": "text",
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
    table = context.resolve_table("raw.zhv")
    df = context.fetchdf(f"SELECT dhid, name, municipality FROM {table} WHERE type='S'")
    df['expanded_name'] = df.apply(lambda x: extract_stop_name(x['name'], x['municipality'], x['dhid']), axis=1)
    
    filtered_df = df.loc[df['expanded_name'] != df['name']]
    del filtered_df['name']
    del filtered_df['municipality']
    if len(filtered_df)==0:
        yield from ()
    yield filtered_df


if __name__ == '__main__':
    if (len(sys.argv) != 4):
        print('Help: zhv_extended_names <stop_name> <municipality name> <globalId>')
        exit(1)
    result = extract_stop_name(sys.argv[1],sys.argv[2],sys.argv[3])
    print(result)
