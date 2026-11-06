"""Regression checks for statistical values, formatting, and stale metadata."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
import publish

class ExportTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.root=Path(self.tmp.name)
        (self.root/'tables').mkdir()
        self.source=self.root/'tables/model.tex'
        self.source.write_text(r'''\begin{tabular}{lcc}
term & 0.123\sym{**} & -0.456 \\
     & (0.010) & (0.020) \\
Wald & 0.010 & 0.020 \\
Bootstrap Wald & 0.030 & 990.000 \\
N & 12 & 9 \\
\end{tabular}
''')
        self.item={'source':'model.tex','file':'model.tex','stars':True,
                   'baseline_source_sha256':publish.sha(self.source),
                   'rows':[{'key':'term','token':'r','display':'Term','baseline_b':'0.123 & -0.456','baseline_se':'(0.010) & (0.020)'}],
                   'stats':{'n':{'key':'N','baseline':'12 & 9'},'c':{'key':'Countries','baseline':'4 & 3'},'p':{'key':'Bootstrap Wald','baseline':'0.030 & --'}}}
        self.template='@@r_b@@ / @@r_se@@ / @@n@@ / @@c@@ / @@p@@'
    def tearDown(self): self.tmp.cleanup()
    def render(self,item=None):
        return publish.regression(item or self.item,self.template,self.root,[],[])
    def test_format_and_uncomputed_bootstrap(self):
        self.assertEqual(self.render(),'0.123$^{**}$ & -0.456 / (0.010) & (0.020) / 12 & 9 / 4 & 3 / 0.030 & --')
    def test_positive_reduction_sign_preserves_se_and_stars(self):
        item=copy.deepcopy(self.item); item['coefficient_sign']=-1
        self.assertIn('-0.123$^{**}$ & 0.456 / (0.010) & (0.020)',self.render(item))
    def test_country_csv_rejects_missing_values(self):
        path=self.root/'countries.csv'
        path.write_text('country_string,g_n1,g_n2,corr_N1_K_out,corr_N1_N2_out,bias_reduction,RMSE_reduction,g_A\nUSA,0.1,0.2,0,0,nan,0.01,0.02\n')
        with self.assertRaisesRegex(ValueError,'Missing'): publish.country(path)
    def test_changed_results_do_not_reuse_country_counts(self):
        self.source.write_text(self.source.read_text().replace('0.123','0.789'))
        output=self.render()
        self.assertIn('0.789',output); self.assertIn('/ -- & -- /',output)
    def test_matching_sample_metadata_used(self):
        metadata={'source_sha256':publish.sha(self.source),'observations':[12,9],'countries':[6,5]}
        self.source.with_suffix('.sample_counts.json').write_text(json.dumps(metadata))
        self.assertIn('/ 6 & 5 /',self.render())
    def test_mismatched_observations_rejected(self):
        metadata={'source_sha256':publish.sha(self.source),'observations':[11,9],'countries':[4,3]}
        self.source.with_suffix('.sample_counts.json').write_text(json.dumps(metadata))
        with self.assertRaisesRegex(ValueError,'do not match'): self.render()
    def test_missing_coefficient_rejected(self):
        self.source.write_text(self.source.read_text().replace('term &','other &'))
        with self.assertRaisesRegex(ValueError,'missing'): self.render()
    def test_wrong_column_count_rejected(self):
        self.source.write_text(self.source.read_text().replace('(0.010) & (0.020)','(0.010)'))
        with self.assertRaisesRegex(ValueError,'columns'): self.render()
    def test_invalid_p_value_rejected(self):
        with self.assertRaisesRegex(ValueError,'p-value'): publish.render_cells(['1.3'],pvalue=True)
    def test_unknown_numeric_format_rejected(self):
        with self.assertRaisesRegex(ValueError,'numerical'): publish.numeric('not a result')

if __name__=='__main__': unittest.main()
