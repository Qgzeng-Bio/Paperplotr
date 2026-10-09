# Journal profiles

One table, `pp_journal_profiles()` in `scripts/lib/production-render.R`, holds every journal-specific number. `pp_render_spec(journal=)` reads it; so do the figure-project layout limits, the export audit (through the spec) and the legacy cm presets. Select a profile with `journal=`, `options(paperplot.journal=)` or `PAPERPLOT_JOURNAL`; the default is `nature`.

| Item | Nature | Cell Press |
|---|---|---|
| Single column | 89 mm | 85 mm |
| 1.5 column | not published (`column="mid"` fails) | 114 mm |
| Double column / full width | 183 mm | 174 mm |
| Max height | 170 mm | 170 mm (skill guard, pending verification) |
| Ordinary text | 5–7 pt | 6–8 pt |
| Panel tags | 8 pt bold, lowercase a/b/c | 8 pt bold (size pending verification), uppercase A/B/C |
| Stroke range | not published | 0.5–1.5 pt |
| Font | Arial (Helvetica accepted by the journal; the skill requires Arial) | Arial |
| Raster | at least 300 dpi, 450 dpi export advised; user default JPG 300 dpi | at least 300 dpi colour; user default JPG 300 dpi |
| Vector/fonts | PDF or EPS, text as vector, embed fonts (TrueType 2 or 42) | embed fonts |

Default role sizes (both profiles): panel title, axis title and body 7 pt; species and annotations 6.5 pt; ticks, legend and caption 6 pt. A `text_pt` override outside the profile range fails; panel tags have their own size. The Cell profile raises `connector` and `separator` strokes to 0.5 pt so every stroke stays in range.

Legacy cm presets agree with the profiles: `nature` 18.3 cm, `nature_half` 8.9 cm, `cell` 17.4 cm, `cell_mid` 11.4 cm, `cell_half` 8.5 cm. `ncomms*`, `single_column`, `double_column` and `square` were not changed (Nature Communications widths not verified).

The user-facing default is PDF + JPG at 300 dpi. JPG is lossy; PDF retains vector text and lines. This default does not rewrite official raster requirements: flag any journal-specific higher resolution or lossless requirement before submission and obtain an explicit export decision, rather than silently changing the user's default.

## Not verified

- Nature 1.5-column width and minimum line weight: the guide does not state them.
- Cell panel-label size and maximum height: no official figure found; values above are marked as pending.
- Nature numbers were read from the pages below through a summarising fetch; recheck against the pages before submission. Cell Press pages returned 403 to direct fetch, so its numbers come from search excerpts of the official figure-guidelines page.

## Sources (checked 2026-10-07)

- Nature: https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/ and https://research-figure-guide.nature.com/figures/building-and-exporting-figure-panels/
- Cell Press: https://www.cell.com/information-for-authors/figure-guidelines
