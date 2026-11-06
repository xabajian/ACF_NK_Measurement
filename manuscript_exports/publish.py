#!/usr/bin/env python3
"""Publish existing Stata results through manuscript-owned LaTeX templates.

Standard library only. No estimation, network, or Stata installation is needed.
All inputs are validated before any destination is replaced.
"""
import argparse
import csv
import hashlib
import json
import math
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ALIASES = {'Productive Forest': 'dlog_prod_area', 'Agricultural Land': 'dlog_land',
           'Forest Area': 'dlog_forest_area_km', 'Mangroves': 'dlog_mangrove_ha',
           'Biomass': 'dlog_b_e', 'Hydropower': 'dlog_hp_gwh', r'\(N\)': 'N'}
NUMBER = re.compile(r'-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cells(text):
    return [s.strip().strip('$').strip() for s in text.split('&')]


def numeric(cell):
    value = re.sub(r'\\sym\{\*+\}|\$|\^\{\*+\}', '', cell).strip()
    value = value.strip('()').replace(',', '')
    if value in ('.', '--', ''):
        return None
    if not NUMBER.fullmatch(value):
        raise ValueError('Unrecognized numerical cell: ' + repr(cell))
    return float(value)


def esttab(path):
    rows = {}; last = None
    for line in path.read_text().splitlines():
        if '&' not in line or not line.rstrip().endswith(r'\\'):
            continue
        parts = cells(line.rstrip()[:-2]); key = parts[0].replace(r'\_', '_')
        if key.startswith('\\') and key != r'\(N\)':
            continue
        values = parts[1:]
        if not key:
            if last and all(v.startswith('(') for v in values):
                rows[last]['se'] = values
            continue
        if not all(numeric(v) is not None or v == '' for v in values):
            raise ValueError(f'{path}: missing result in {key}')
        key = ALIASES.get(key, key)
        if key in rows:
            raise ValueError(f'{path}: duplicate row {key}')
        rows[key] = {'b': values}; last = key
    if 'N' not in rows:
        raise ValueError(f'{path}: no observation counts')
    width = len(rows['N']['b'])
    for key, row in rows.items():
        for kind, vals in row.items():
            if len(vals) != width:
                raise ValueError(f'{path}: wrong number of columns in {key}/{kind}')
    return rows


def render_cells(values, stars=False, count=False, pvalue=False):
    result = []
    for value in values:
        number = numeric(value)
        if number is None:
            result.append('--'); continue
        if pvalue and number == 990:
            result.append('--'); continue  # analysis's explicit uncomputed-test sentinel
        if pvalue and not 0 <= number <= 1:
            raise ValueError(f'Invalid p-value {value}')
        if count:
            if number != int(number) or number < 0:
                raise ValueError(f'Invalid count {value}')
            result.append(f'{int(number):,}'); continue
        if stars:
            value = re.sub(r'\\sym\{(\*+)\}', lambda m: '$^{'+m[1]+'}$', value)
        else:
            value = re.sub(r'\\sym\{\*+\}', '', value)
        result.append(value)
    return ' & '.join(result)


def escaped(text):
    replacements = {'&': r'\&', '%': r'\%', '_': r'\_', '#': r'\#', '$': r'\$'}
    return ''.join(replacements.get(c, c) for c in text)


def regression(item, text, analysis, warnings, changes):
    source = analysis/'tables'/item['source']; rows = esttab(source)
    for row in item['rows']:
        key = row['key']
        if key not in rows or 'se' not in rows[key]:
            raise ValueError(f'{source}: required coefficient/SE missing: {key}')
        for kind in ('b', 'se'):
            values = rows[key][kind]
            if kind == 'b' and item.get('coefficient_sign', 1) == -1:
                values = [re.sub(NUMBER, lambda m: format(-float(m[0]), '.3f'), value, count=1) for value in values]
            result = render_cells(values, item['stars'])
            text = text.replace('@@'+row['token']+'_'+kind+'@@', result)
            old = cells(row['baseline_'+kind]); new = cells(result)
            if [numeric(v) for v in old] != [numeric(v) for v in new]:
                changes.append(f"{item['file']} | {row['display']} {kind} | {'; '.join(old)} -> {'; '.join(new)}")
    metadata_path = analysis/'tables'/(source.stem+'.sample_counts.json')
    metadata = json.loads(metadata_path.read_text()) if metadata_path.exists() else None
    nvals = rows['N']['b']
    for token, spec in item['stats'].items():
        key = spec['key']
        if key == 'Countries':
            if metadata and metadata['source_sha256'] == sha(source):
                if metadata['observations'] != [int(numeric(v)) for v in nvals]:
                    raise ValueError(f'{metadata_path}: sample counts do not match source N')
                vals = [str(v) for v in metadata['countries']]
                if len(vals) != len(nvals):
                    raise ValueError(f'{metadata_path}: incorrect column count')
            else:
                # Never reuse historical country counts for a changed result file.
                baseline_n = next(s['baseline'] for s in item['stats'].values() if s['key']=='N')
                valid = (sha(source) == item['baseline_source_sha256'] and
                         [numeric(v) for v in cells(baseline_n)] == [numeric(v) for v in nvals])
                vals = cells(spec['baseline']) if valid else ['--']*len(nvals)
                warnings.append(f"{item['file']}: country counts {'retained from the original manuscript (not independently verified)' if valid else 'unavailable; displayed as --'}. Run 30_run_analysis.do on the producing script to capture e(sample) counts.")
        else:
            if key not in rows:
                raise ValueError(f'{source}: required statistic missing: {key}')
            vals = rows[key]['b']
        result = render_cells(vals, count=key in ('N','Countries'), pvalue=key in ('Wald','Bootstrap Wald'))
        text = text.replace('@@'+token+'@@', result)
        if [numeric(v) for v in cells(spec['baseline'])] != [numeric(v) for v in cells(result)]:
            changes.append(f"{item['file']} | {key} | {spec['baseline'].strip()} -> {result}")
    expected = {row['key'] for row in item['rows']}
    extra = {k for k,v in rows.items() if 'se' in v} - expected
    if extra - {'dlog_mangrove_ha'} - set(item.get('hidden_coefficients', [])):
        raise ValueError(f'{source}: unmapped coefficient rows: {sorted(extra)}')
    if 'dlog_mangrove_ha' in extra:
        if any(numeric(v) != 0 for v in rows['dlog_mangrove_ha']['b']):
            raise ValueError(f'{source}: omitted EU mangrove row is no longer zero; update template')
    return text


def wald(source):
    values = {}
    for line in source.read_text().splitlines():
        if line.startswith(('BCH &', 'Driscoll-Kraay &')):
            parts = cells(line.rstrip()[:-2]); values[(parts[0], parts[1])] = parts[2:]
    order = [('BCH','pds','PDS'),('BCH','lasso','LASSO'),('BCH','post lasso','post-LASSO'),
             ('Driscoll-Kraay','No controls','TWFE'),('Driscoll-Kraay','Controls','TWFE + Controls'),
             ('Driscoll-Kraay','Controls + Trend','TWFE + Controls + Trends')]
    return '\n'.join(f'{model} & {display} & '+render_cells(values[(model,key)],pvalue=True)+r' \\' for model,key,display in order)


def country(source):
    names = json.loads((HERE/'country_names.json').read_text()); output = []; seen = set()
    if source.suffix == '.csv':
        fields = ['g_n1', 'g_n2', 'corr_N1_K_out', 'corr_N1_N2_out', 'bias_reduction', 'RMSE_reduction', 'g_A']
        for row in csv.DictReader(source.read_text().splitlines()):
            code = row['country_string']
            if code in seen or code not in names: raise ValueError(f'Unknown/duplicate country {code}')
            seen.add(code)
            vals = [float(row[k]) for k in fields]
            if not all(math.isfinite(v) for v in vals): raise ValueError(f'Missing value for {code}')
            output.append(' & '.join([code, escaped(names[code])] + [f'{v*10000:.1f}' if k in (4,5) else f'{v:.4f}' for k,v in enumerate(vals)]) + r' \\')
        if not output: raise ValueError(f'{source}: no country rows')
        return '\n'.join(output)
    for line in source.read_text().splitlines():
        if not re.match(r'^[A-Z]{3}&',line):
            continue
        parts = cells(line.split(r'\tabularnewline')[0]); code = parts[0]
        if len(parts)!=8 or code in seen:
            raise ValueError(f'{source}: malformed/duplicate country row {code}')
        seen.add(code)
        if code not in names:
            raise ValueError(f'Add country name for {code} to country_names.json')
        for value in parts[1:]:
            if numeric(value) is None: raise ValueError(f'Missing value for {code}')
        output.append(' & '.join([code,escaped(names[code])]+parts[1:])+r' \\')
    if not output: raise ValueError(f'{source}: no country rows')
    return '\n'.join(output)


def build(analysis, manuscript, mode='all'):
    manifest = json.loads((HERE/'manifest.json').read_text())
    outputs = {}; warnings = []; changes = []; provenance = []
    if mode in ('all','tables'):
        for item in manifest['tables']:
            template = manuscript/'tables/templates'/item['file']
            text = template.read_text(); kind = item['kind']
            if kind == 'regression': text = regression(item,text,analysis,warnings,changes)
            elif kind == 'wald': text = text.replace('@@wald_rows@@',wald(analysis/'tables'/item['source']))
            elif kind == 'country': text = text.replace('@@country_rows@@',country(analysis/'tables'/item['source']))
            elif kind == 'editorial': warnings.append(f"{item['file']}: editorial/descriptive table; maintained in tables/templates, not re-estimated.")
            if item.get('note'): warnings.append(item['file']+': '+item['note'])
            if '@@' in text: raise ValueError(f"Unresolved template token in {item['file']}")
            outputs[manuscript/'tables/generated'/item['file']] = ('% Generated by manuscript_exports/publish.py; edit tables/templates instead.\n'+text).encode()
            if 'source' in item:
                path=analysis/'tables'/item['source']
                provenance.append({'source':str(path.relative_to(analysis)),'sha256':sha(path),'output':'tables/generated/'+item['file']})
    if mode in ('all','figures'):
        for item in manifest['figures']:
            source=analysis/'figs'/item['source']; data=source.read_bytes()
            if source.suffix=='.pdf' and not data.startswith(b'%PDF-'): raise ValueError(f'Invalid PDF: {source}')
            if source.suffix=='.png' and not data.startswith(b'\x89PNG'): raise ValueError(f'Invalid PNG: {source}')
            outputs[manuscript/'figs/generated'/item['file']]=data
            provenance.append({'source':'figs/'+item['source'],'sha256':sha(source),'output':'figs/generated/'+item['file']})
    report = ['# Manuscript export report', '', 'Exports use existing analysis outputs; this command does not re-estimate models.',
              '', '## Items requiring attention', ''] + ['- '+w for w in warnings]
    report += ['', '## Numerical changes from the original pasted regression tables', '']+changes
    report += ['', 'Wald and country-level tables are regenerated in full; their old pasted numbers are not used.',
               'Narrative findings and figure captions remain authored text and should be checked when results change.',
               'Main figures use absolute-bias outputs; the SI separately reports RMSE. MSE diagnostic figures are copied from figs/RMSE_decomp1.pdf and figs/RMSE_decomp2.pdf, produced by scripts/6_appendix_figures.do.', '']
    outputs[manuscript/'tables/generated'/('export_report_'+mode+'.md')]='\n'.join(report).encode()
    outputs[manuscript/'tables/generated'/('provenance_'+mode+'.json')]=(json.dumps(provenance,indent=2)+'\n').encode()
    return outputs, warnings


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--analysis',type=Path,default=HERE.parent)
    p.add_argument('--manuscript',type=Path,default=HERE.parent.parent/'ACF_Manuscript')
    p.add_argument('--mode',choices=['all','tables','figures'],default='all')
    p.add_argument('--success-marker',type=Path)
    p.add_argument('--check',action='store_true',help='Validate inputs without writing')
    args=p.parse_args()
    outputs,warnings=build(args.analysis,args.manuscript,args.mode)
    if not args.check:
        for path,data in outputs.items():
            path.parent.mkdir(parents=True,exist_ok=True)
            temporary=path.with_name(path.name+'.tmp')
            temporary.write_bytes(data); temporary.replace(path)
    if args.success_marker: args.success_marker.write_text('success\n')
    print(('Validated' if args.check else 'Published')+f' {len(outputs)-2} table/figure files. {len(warnings)} notes in export_report_{args.mode}.md.')

if __name__=='__main__': main()
