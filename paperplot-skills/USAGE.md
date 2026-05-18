# Using paperplot-skills

## How to invoke

Ask Codex to use `paperplot-skills` when you need a professional scientific figure diagnosis, redesign, or reproducible R/ggplot2 plot.

Example:

```text
Use paperplot-skills to redesign this figure as a manuscript-ready multi-panel plot. Data are in data.csv. The main message is ... The figure role is main figure. Please output PDF, PNG, notes, metadata, QA, and old-vs-new comparison.
```

## What to provide

Best input:

- data file,
- current plot image if redesigning,
- current plotting code if available,
- scientific message,
- figure role: main, supplement, diagnostic, or exploratory,
- sample/group/metric/value columns,
- units, transformations, normalization, and statistical test details.

Minimum input depends on task:

| user input | skill behavior |
|---|---|
| image only | diagnose and propose redesign; request data for faithful redraw |
| code only | review and improve plotting code; avoid claiming data-backed correctness without data |
| data only | profile data, select template, generate plot and sidecars |
| image + data | diagnose old figure, redraw from data, compare old vs new |
| image + code + data | full redesign, reproducibility, QA, and comparison |

## What the skill outputs

Default outputs:

- PDF vector figure,
- PNG preview,
- plotting script,
- notes markdown,
- metadata JSON,
- QA markdown,
- label key or sample order sidecars when labels are abbreviated/ranked,
- optional visual QA report after rendering.

## User responsibilities

The skill can catch many visual and scientific risks, but the user must confirm:

- biological meaning of groups,
- units and denominators,
- statistical model/test correctness,
- sample pairing or repeated-measure design,
- journal-specific final formatting requirements,
- whether manual Illustrator/PDF edits changed scientific meaning.
