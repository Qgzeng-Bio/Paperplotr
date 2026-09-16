# Locked environment and safe installation

0.7 is a release candidate. Runtime and skill code are separate; plotting never installs or upgrades dependencies.

## Runtime

Use an ASCII, space-free prefix. The tested exact system lock is macOS ARM64:

```sh
conda create --prefix "$HOME/.local/share/paperplot/runtime-0.7.0" --file paperplot-skills/conda-osx-arm64.lock
"$HOME/.local/share/paperplot/runtime-0.7.0/bin/Rscript" --vanilla paperplot-skills/scripts/bootstrap-environment.R "$HOME/.local/share/paperplot/runtime-0.7.0"
"$HOME/.local/share/paperplot/runtime-0.7.0/bin/python" -m pip install -r paperplot-skills/requirements.lock
paperplot-skills/scripts/paperplot-run
```

R 4.6.0 / Python 3.13 / Bioconductor 3.23. The pairing follows the [official release table](https://bioconductor.org/about/release-announcements/). Conda manages system libraries; renv restores the separate R library from renv.lock. No installation into system/user R libraries.

For other platforms, `conda env create --prefix <prefix> --file paperplot-skills/environment.yml` is a portable bootstrap, not an exact tested platform lock. Validate and record a platform-specific lock before claiming formal support. Override the runtime path with `PAPERPLOT_ENV`.

Supply legally installed Arial Regular/Bold/Italic. No font files are distributed. Doctor reports package versions, exact font/interpreter paths and missing capabilities. Preview/demo cannot certify production typography.

## Skill installation

After validating the runtime, from a reviewed clean checkout:

```sh
PAPERPLOT_SOURCE_DIR="$PWD/paperplot-skills" PAPERPLOT_OVERWRITE=1 sh install-paperplot-skill.sh
```

Default destination is `~/.agents/skills/paperplot-skills`. Existing directories or broken links are backed up. Validate the staged runtime before switching; then execute installed commands and actual PDF/SVG/PNG exports from outside the checkout. Failed post-switch checks restore the old installation.

`installation.json` records version, commit, dirty-source count, environment and code/lock hashes. Remote `PAPERPLOT_REF=<reviewed commit>` is resolved and downloaded to staging. Inspect the installer before execution.

`PAPERPLOT_PROFILE=runtime` includes documented user commands. `full` also includes developer tests/reports. `PAPERPLOT_DEST` changes the skills root; invalid profiles/names fail before replacement.

Link other configured agent entry points to the stable .agents installation, not the development checkout. Preserve existing real directories first. Verify installed `scripts/paperplot-run` and `scripts/install-self-test.R` from another directory and restart the agent to refresh discovery.
