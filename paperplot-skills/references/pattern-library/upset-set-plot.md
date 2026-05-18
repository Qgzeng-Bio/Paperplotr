# Pattern: UpSet / Set Plot

Derived from UpSet and Venn-like replica cases using scalable set-intersection matrices.

## Applies When

- The question concerns intersections among 3 or more sets.
- Exact set membership is available.
- Intersection size and set size are both relevant.

## Does Not Apply When

- There are only two sets; a simple bar or two-way table may suffice.
- Membership data are missing and only summary counts exist.
- The set count is so high that intersection rows become unreadable.
- Decorative Venn overlap areas are expected to be quantitative.

## Input Data Structure

- Binary membership table with one row per item and one logical column per set, or long membership table with `item` and `set`.
- Optional annotations: `category`, `score`, `label_priority`.

## Visual Encoding

- Matrix dots/lines encode membership combination.
- Bars encode intersection size and optional set size.
- Color encodes one grouping variable only if it helps interpretation.

## Layout

- Sort by intersection size or a biologically meaningful order.
- Show top intersections in the main figure; move rare combinations to supplement.
- Keep membership matrix aligned and compact.

## Typography And Marks

- Dot size fixed and readable at target width.
- Bar axis labels concise.
- Set names may need wrapping or sidecar if long.

## Color Strategy

- Mostly monochrome matrix with one accent for highlighted intersections.
- Avoid coloring every set differently in the matrix.

## Common Failure Modes

- Too many intersections in one panel.
- Venn-like shapes imply inaccurate area.
- Set labels dominate bars.
- Membership table is not reproducible.

## Nature-Like Principle

Set figures should trade decorative overlap for exact, scalable intersection reading.

## Existing Templates

- No direct template.
- `rank-plus-key-metrics-template.R` shares top-N and sidecar strategies.

## New Template Need

`upset-summary-template.R` is appropriate only with explicit binary-membership validation and graceful fallback when optional packages are absent.

## QA Checklist

- Membership schema is validated.
- Sorting rule is recorded.
- Top-N cutoff is stated.
- Rare intersections are not silently dropped.
- Set labels remain readable.

## Visual QA Focus

- `line_burden_score` and `thumbnail_content_density` for matrix/bar density.
- `text_burden_score` for set names and intersection labels.

## Old-vs-New Criteria

Improvement means intersections are easier to compare, set membership is exact, long labels are controlled, and top-N simplification is documented.
