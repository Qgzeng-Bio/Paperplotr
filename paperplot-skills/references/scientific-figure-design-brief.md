# Scientific Figure Design Brief

Complete this brief before writing or rewriting plotting code.

## Required Decisions

- Main question: what should a reader learn first?
- Figure role: main figure, extended data, supplement, or diagnostic preview.
- Input data: path, table shape, required columns, and units.
- Sample order: ranked, biological order, experimental order, alphabetical, or user supplied.
- Panel plan: panels to keep, remove, merge, or move to notes/extended data.
- Encoding plan: x, y, color, fill, size, facets, labels, and legend semantics.
- Candidate layouts: at least one conservative option and one compressed option when compression is requested.
- Rejection criteria: what would make the figure worse than the current version?

## Old Figure Redesign

When an old figure or script exists, first list concrete issues:

- unnecessary panels
- gridlines without reading value
- inconsistent panel sizes
- overlapping title, labels, legend, or data
- unclear color meaning
- too many encodings in one panel
- compressed metrics that hide original units

Do not start by copying the old layout. Preserve only the parts that support the scientific message.

## Notes Requirement

The sidecar notes must include design decisions, not only file paths. A reader should be able to see why the final layout was chosen.
