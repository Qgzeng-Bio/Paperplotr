# PaperPlotR (development version)

* The default discrete palette (`graphpad_discrete`) is re-ordered for
  deuteranopia separation: the old order placed green and red at positions
  3-4, which collapse to CIELAB dE 0.7 under the Viénot 1999 simulation.
  Minimum pairwise dE is now 87.0 (2 groups), 28.1 (3-4), 20.9 (5) and
  19.2 (6). Figures made with the previous order will change colour; the
  scientific content is unaffected. `pp_palette_cvd_min_delta_e()` reports
  the value and `scripts/test-palette-cvd.R` guards it in CI.
* `License: MIT` now ships a single full-text `LICENSE` file so hosting
  services and R both recognise the license.

* `scale_fill_lab()` and `scale_color_lab()` now expose `guide`, allowing
  callers to suppress or customize legends without duplicate-argument errors.
* `layout_lab()` can now add publication-style panel tags directly via
  `tag_levels`, `tag_size`, `tag_face`, `tag_family`, and `tag_position`.
* `save_lab()` and `save_lab_plot()` now validate named graphics devices before
  calling `ggplot2::ggsave()` and support `device = "quartz_pdf"` for native
  macOS PDF output, `device = "ragg_png"` and `device = "ragg_tiff"` for
  ragg-backed raster output, and `device = "svglite"` for svglite-backed SVG.
* `save_lab()` and `save_lab_plot()` now check that the exported file exists
  and is not suspiciously small. The check can be tuned with
  `min_output_size_bytes` or disabled with `validate_output = FALSE`.
* Domain-specific semantic color dictionaries are now opt-in in
  `available_group_dictionaries(include_examples = TRUE)`. They remain
  resolvable by name for backward compatibility, with a warning that encourages
  project-specific registration via `register_group_dictionary()`.
* Added a dedicated gallery vignette demonstrating semantic colors,
  multi-panel composition with tags, and explicit export devices.
* Added visual regression snapshots for semantic group mapping and tagged
  multi-panel gallery layouts.
* Local visual-check outputs and accidental `Rplots.pdf` artifacts are ignored
  by git.

# PaperPlotR 0.1.0

* Initial release.
* `theme_lab()`: lab-standard ggplot2 theme with journal-consistent defaults.
* `fig_specs`, `get_fig_size_cm()`, `panel_size()`: canonical panel size system.
* `journal_preset()`, `available_journal_presets()`: Cell, Nature, Nature Communications presets.
* `save_lab()`, `save_lab_plot()`: export helpers with font-size validation.
* `layout_lab()`: patchwork-based multi-panel composition.
* `lab_palette()`, `scale_fill_lab()`, `scale_color_lab()`: discrete palette system with 15 built-in palettes.
* `group_colors()`, `scale_fill_groupmap()`, `scale_color_groupmap()`: semantic group-to-color dictionaries.
* `plot_box_paper()`, `plot_violin_paper()`, `plot_dot_paper()`: high-level comparison plot functions.
* `layer_points_paper()`, `layer_summary_paper()`, `layer_signif_paper()`: reusable comparison layers.
* `render_paperplotr_examples()`: gallery of example figures.
