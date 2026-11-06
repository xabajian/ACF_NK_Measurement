"""Create a temporary instrumented copy; never edit original analysis scripts."""
import argparse
import re
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--analysis',type=Path,required=True)
p.add_argument('--script',required=True)
p.add_argument('--output',type=Path,required=True)
p.add_argument('--success-marker',type=Path,required=True)
a=p.parse_args()
if Path(a.script).name != a.script or not a.script.endswith('.do'):
    raise ValueError('Supply a filename in scripts/, not a path')
source=a.analysis/'scripts'/a.script
text=source.read_text().replace('/Users/xabajian/Documents/GitHub/ACF_NK_Measurement',str(a.analysis))
# Match complete esttab commands, including /// continuation lines.
pattern=re.compile(r'^esttab\s+(?P<models>m\d+(?:\s+m\d+)*)\s+using\s+"(?P<file>[^"\n]+)"[^\n]*',re.M)
lines=text.splitlines(keepends=True); output=[]; i=0; hooks=0
while i<len(lines):
    line=lines[i]; match=pattern.match(line); output.append(line); i+=1
    if not match: continue
    while output[-1].rstrip().endswith('///'):
        if i>=len(lines): raise ValueError('Unterminated esttab command')
        output.append(lines[i]); i+=1
    # Country identifier is available in both regression-producing scripts.
    # Other scripts (e.g. decomposition) have no country-count display.
    if a.script in ('0_CWON_Regs.do','2_Tornqvist_Indices_Regs.do'):
        output.append('\ndo "$ACF_ANALYSIS/manuscript_exports/40_capture_samples.do" "'+match['file']+'" "'+match['models']+'"\n')
        hooks+=1
if a.script in ('0_CWON_Regs.do','2_Tornqvist_Indices_Regs.do') and not hooks:
    raise ValueError('No esttab commands recognized; inspect changed analysis syntax')
a.output.write_text(''.join(output)); a.success_marker.write_text('success\n')
print(f'Prepared {a.script} with {hooks} country-count capture points.')
