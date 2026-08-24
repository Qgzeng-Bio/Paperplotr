# Panel geometry QA validation

| scenario | pass | detected panels | panel ratio | content ratio | risks |
|---|---|---:|---:|---:|---|
| visual-panel-equal-balance | True | 2 | 1.0 | 1.0 | excessive_blank_margin, grayscale_discrimination_risk, low_content_density |
| visual-panel-unequal-imbalance | True | 2 | 6.3833 | 9.5432 | grayscale_discrimination_risk, low_content_density, panel_blank_space_imbalance, panel_data_region_imbalance, panel_data_region_mismatch, panel_size_imbalance |
