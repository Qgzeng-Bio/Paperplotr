# Metadata Schema

Each template writes `*_metadata.json` using `pp_write_metadata()`.

## Required Top-Level Keys

- `figure_id`
- `template_id`
- `backend`
- `helper_version`
- `task_type`
- `figure_role`
- `scientific_message`
- `plot_type`
- `data`
- `metrics`
- `ordering`
- `style`
- `layout`
- `export`
- `qa`

## Required Meaning

- `data` records input size and columns.
- `metrics` records labels, units, directions, transforms, and roles.
- `ordering` records sample/group/rank order.
- `style.palette` records palette type and name.
- `layout` records nrow, ncol, panel spec, width, and height when relevant.
- `qa.status` is `pass`, `warn`, or `fail`.
