# Pressure Scenarios

Use these scenarios to evaluate whether the skill changes agent behavior, not only whether templates run.

## Figure1 genome quality

Prompt shape: "Redraw this genome quality figure using the skill."

Expected behavior:

- Diagnose the source figure before coding.
- Remove panel A when the user says it is unnecessary.
- Remove unnecessary gridlines.
- Use consistent panel sizes.
- Use GraphPad-like colors.
- Fix title, label, and panel tag overlaps.
- Do not reproduce the old layout by default.
- Write `figure_spec`, `metric_spec`, metadata JSON, and QA report.

Pass criteria:

- PDF, PNG, notes, metadata, and QA sidecars exist.
- The final figure uses a documented layout and sample ordering.
- Dense x-axis labels are handled with a recorded label strategy.

Failure behavior:

- "Recreated the original figure" with only minor theme changes.
- Keeps panel A after the user removes it.
- Leaves the user to identify color or layout problems.
- Omits metadata or QA sidecars.

## Six heterogeneous quality metrics

Prompt shape: "Integrate QV, contig N50, gaps, BUSCO, telomeres, and score."

Expected behavior:

- Start from a 2x3 small multiples design.
- Preserve original units.
- Share sample order across panels.
- Avoid dot/bubble heatmap by default.
- Record metric directions and transforms in `metric_spec`.

Pass criteria:

- The notes explain why small multiples were chosen.
- Facet labels retain metric units.
- Metadata records layout and ordering.

Failure behavior:

- Compresses all metrics into one dot/bubble heatmap.
- Uses color, size, labels, and normalization together.
- Makes the compressed figure harder to read than six point panels.

## Percentage color semantics

Prompt shape: "Does this color mean 100%?"

Expected behavior:

- State whether color encodes percentage, rank, group, or normalized value.
- Ensure legend title includes percent sign when color encodes percentage.
- Avoid ambiguous purple/gradient interpretations.

Pass criteria:

- Metadata records palette type and color semantics.
- Notes state whether values are percent, rank, or normalized.

Failure behavior:

- Leaves color semantics implicit.
- Uses a colorbar without units.

## Long sample labels

Prompt shape: "Make this sample-heavy figure publication-ready."

Expected behavior:

- Run `pp_label_strategy()`.
- Use rotate, wrap, abbreviate, every-N labels, horizontal layout, or label key as needed.

Pass criteria:

- Label density status is recorded in notes and QA report.
- Severe density is not ignored.

Failure behavior:

- Shows every long label on a narrow x axis.
- Claims manuscript readiness despite label collisions.

## Too many groups

Prompt shape: "Color all 20 groups in one plot."

Expected behavior:

- Warn when group count exceeds palette capacity.
- Recommend faceting, filtering, ranking, or grouping low-priority categories.

Pass criteria:

- QA report includes a palette warning.

Failure behavior:

- Interpolates colors silently and leaves interpretation to the reader.

## Old figure refinement

Prompt shape: "Make this existing plot publication-ready."

Expected behavior:

- List concrete source-figure issues first.
- Preserve original files.
- Create versioned outputs.
- Explain what changed and why.

Pass criteria:

- Notes document source problems, design decisions, and known limitations.

Failure behavior:

- Starts by editing the original script without a design diagnosis.
- Claims manuscript readiness without visual QA.
