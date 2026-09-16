#!/usr/bin/env python3
"""Generate the user inventory from the one executable recipe manifest."""
import argparse
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
with (root / 'recipes/recipe_manifest.csv').open(newline='') as stream:
    entries = list(csv.DictReader(stream))
assert len(entries) == 84 and len({e['recipe_id'] for e in entries}) == 84
lines = ['# Executable recipe catalog', '',
         'Generated from recipes/recipe_manifest.csv; do not maintain a second support list.',
         'Every entry requires real input and its named backend. Legacy classifications are not acceptance results.',
         'See ../code-recipe-contract.md for conditional parameters, types, keys, units and statistical rules.', '',
         '| ID | Handler / variant | Backend | Required columns | Optional columns | Canvas (mm) |',
         '|---|---|---|---|---|---|']
for e in entries:
    lines.append(f"| {e['recipe_id']} | {e['handler']} / {e['variant']} | {e['backend']} | {e['required_roles']} | {e['optional_roles']} | {float(e['default_width_cm'])*10:g} × {float(e['default_height_cm'])*10:g} |")
content = '\n'.join(lines) + '\n'
path = root / 'references/code-recipes/recipe-library.md'
if args.check:
    if path.read_text() != content:
        raise SystemExit('Recipe documentation has drifted; regenerate with scripts/catalog.py.')
else:
    path.write_text(content)
print(f'{len(entries)} recipe IDs; generated catalog matches the executable manifest.')
