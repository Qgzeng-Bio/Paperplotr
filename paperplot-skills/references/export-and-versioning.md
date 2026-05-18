# Export And Versioning

Use versioned exports so figure iterations remain auditable.

## Required Defaults

- Timestamped output stem: `figure_id_YYYYMMDD-HHMMSS`.
- PDF for vector editing.
- PNG for preview.
- 600 dpi for raster output.
- Refuse to overwrite old outputs.
- Write sidecar notes next to outputs.
- Write machine-readable metadata JSON.
- Write a QA report.

## Helper Functions

Use:

```r
output_files <- pp_save_all(p, output_stem, preset = "nature_half")
pp_write_notes(notes_path, figure_id, input_path, output_files, preset, figure_spec = figure_spec)
pp_write_metadata(metadata_path, figure_spec, metric_spec, output_files, layout = layout, palette = palette, ordering = ordering, qa = qa)
pp_write_qa_report(qa_path, qa_results)
```

## Sidecar Contract

Each template should generate:

```text
*.pdf
*.png
*_notes.md
*_metadata.json
*_qa.md
```

## Notes Must Record

- scientific purpose
- input path
- script/template used
- output paths
- file sizes
- preset and layout
- metric labels, units, directions, and transforms
- sample/order rule
- palette semantics
- label strategy
- QA gate results
- remaining issues
