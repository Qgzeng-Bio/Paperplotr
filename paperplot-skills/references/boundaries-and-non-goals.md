# Boundaries And Non-Goals

PaperPlotR is a ggplot2-based scientific figure standardization workflow. It is not a general visual design or illustration system.

## Do Not Use PaperPlotR For

- Mechanism diagrams.
- Pathway cartoons.
- Graphical abstracts.
- Flowcharts.
- Network architecture diagrams.
- Complex SVG illustrations.
- Interactive dashboards.
- Image generation or AI art.
- Python-only plotting workflows.

## Recommended Handoffs

- Use Mermaid or Graphviz for structured diagrams and flowcharts.
- Use Illustrator, Inkscape, or an SVG workflow for mechanism figures and complex vector editing.
- Use PowerPoint, Keynote, or presentation tooling for slide-like composites.
- Use a web visualization workflow for interactive dashboards.
- Use Python/matplotlib only when the user explicitly requires Python.

## Borderline Cases

Use PaperPlotR if the figure is fundamentally a statistical plot, even if it needs careful layout, labels, or export. Do not use PaperPlotR if the core task is drawing conceptual objects rather than plotting data.
