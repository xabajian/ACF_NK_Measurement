"""Bind Stata e(sample) country counts to the exact table they describe."""
import csv
import hashlib
import json
import sys
from pathlib import Path

source, csv_path, marker = map(Path, sys.argv[1:])
with csv_path.open() as handle:
    rows = list(csv.DictReader(handle))
if not rows:
    raise ValueError('Empty estimation metadata')
result = {'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'models': [r['model'] for r in rows],
          'observations': [int(r['observations']) for r in rows],
          'countries': [int(r['countries']) for r in rows]}
output = source.with_suffix('.sample_counts.json')
temporary = output.with_suffix('.json.tmp')
temporary.write_text(json.dumps(result, indent=2)+'\n'); temporary.replace(output)
marker.write_text('success\n')
