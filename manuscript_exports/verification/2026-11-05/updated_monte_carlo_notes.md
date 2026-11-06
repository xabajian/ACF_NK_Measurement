# Updated Monte Carlo verification

The completed run contains 10,000,000 valid draws, no missing values, and all 103 country indices. Indices 101, 102, and 103 have 96,818, 96,626, and 97,072 draws, respectively. The within-replication sampler now selects uniformly from the actual eligible row count.

- Median absolute-bias reduction: 20.0768 basis points (previously 20.7924).
- Mean: 51.6734 basis points (previously 53.0207).
- Standard deviation: 93.8298 basis points.
- Absolute bias increases in 8.95753% of draws and decreases in 91.04247%; no draws have exactly zero reduction.
- Deterioration conditional on gamma1 <= 0.05: 13.2920%.
- Deterioration conditional on gamma2 >= 0.05: 12.2611%.
- The 90th-percentile trimming threshold for fitted curves is 137.5492 basis points. All reported overall statistics use the untrimmed sample.

The qualitative conclusion is unchanged. The country coverage correction modestly reduces the estimated gains and increases deterioration by about 0.49 percentage points. The fitted relationships retain their directions: increasing with the non-renewable elasticity and more weakly decreasing with the renewable elasticity.

Updated 0.main.chat.tex and 0.SI.chat.tex, including the robustness discussion and figure captions, to reflect the completed 103-country exercise. Ran 00_publish.do successfully; its log confirms publication of 37 outputs. The previously reported baseline and unconditional country-level results remain unchanged. The pending scheduled check was paused because this verification was completed immediately.

This note supersedes the earlier warning about 100-country Monte Carlo coverage in Rerun-verification-and-robustness-notes.md.
