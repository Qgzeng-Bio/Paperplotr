# PaperPlotR (development version)

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
