#!/usr/bin/env sh
set -eu
OWNER="${PAPERPLOT_OWNER:-Qgzeng-Bio}"
REPO="${PAPERPLOT_REPO:-Paperplotr}"
REF="${PAPERPLOT_REF:-main}"
PROFILE="${PAPERPLOT_PROFILE:-runtime}"
SKILL_NAME="${PAPERPLOT_SKILL_NAME:-paperplot-skills}"
DEST_ROOT="${PAPERPLOT_DEST:-$HOME/.agents/skills}"
SOURCE="${PAPERPLOT_SOURCE_DIR:-}"
COMMIT="${PAPERPLOT_COMMIT:-unknown}"
DIRTY=unknown
case "$PROFILE" in runtime|full) ;; *) echo "Unknown profile: $PROFILE" >&2; exit 1;; esac
case "$SKILL_NAME" in ""|.|..|*[!a-zA-Z0-9_-]*) echo "Invalid skill name" >&2; exit 1;; esac
case "$DEST_ROOT" in ""|/) echo "Invalid destination root" >&2; exit 1;; esac
mkdir -p "$DEST_ROOT"
DEST_ROOT="$(cd "$DEST_ROOT" && pwd -P)"
DEST="$DEST_ROOT/$SKILL_NAME"
BACKUP_ROOT="${PAPERPLOT_BACKUP_ROOT:-$(dirname "$DEST_ROOT")/skill-backups}"
if { [ -e "$DEST" ] || [ -L "$DEST" ]; } && [ "${PAPERPLOT_OVERWRITE:-0}" != 1 ]; then
  echo "Destination exists: $DEST; set PAPERPLOT_OVERWRITE=1 to back up and replace it." >&2
  exit 1
fi
LOCK="$DEST_ROOT/.$SKILL_NAME-install-lock"
mkdir "$LOCK" 2>/dev/null || { echo "Another installer owns $LOCK" >&2; exit 1; }
STAGE="$(mktemp -d "$DEST_ROOT/.$SKILL_NAME-stage.XXXXXX")"
BACKUP=""
SWITCHED=0
COMPLETE=0
cleanup() {
  if [ "$COMPLETE" != 1 ] && [ "$SWITCHED" = 1 ]; then
    # Preserve a failed candidate as well; restore the prior installation.
    mv "$DEST" "$STAGE/failed-install"
    if [ -n "$BACKUP" ]; then mv "$BACKUP" "$DEST"; fi
  fi
  rm -rf "$STAGE"
  rmdir "$LOCK"
}
trap cleanup EXIT HUP INT TERM
download() {
  if command -v curl >/dev/null 2>&1 && curl -fsSL "$1" -o "$2"; then return; fi
  if command -v wget >/dev/null 2>&1 && wget -q -O "$2" "$1"; then return; fi
  echo "Download failed; the previous installation remains intact." >&2
  exit 1
}
if [ -n "$SOURCE" ]; then
  SOURCE="$(cd "$SOURCE" && pwd -P)"
  if git -C "$SOURCE" rev-parse --verify HEAD >/dev/null 2>&1; then
    COMMIT="$(git -C "$SOURCE" rev-parse HEAD)"
    DIRTY="$(git -C "$SOURCE" status --porcelain -- . | wc -l | tr -d ' ')"
  fi
else
  download "https://api.github.com/repos/$OWNER/$REPO/commits/$REF" "$STAGE/commit.json"
  COMMIT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["sha"])' "$STAGE/commit.json")"
  case "$COMMIT" in *[!a-f0-9]*|"") echo "Invalid resolved commit" >&2; exit 1;; esac
  [ "${#COMMIT}" = 40 ] || { echo "Invalid resolved commit length" >&2; exit 1; }
  DIRTY=0
  download "https://codeload.github.com/$OWNER/$REPO/zip/$COMMIT" "$STAGE/repo.zip"
  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$STAGE/repo.zip" -d "$STAGE/archive"
  else
    python3 - "$STAGE/repo.zip" "$STAGE/archive" <<'PY'
import sys, zipfile
from pathlib import Path
archive, destination = sys.argv[1:]
root = Path(destination).resolve()
with zipfile.ZipFile(archive) as z:
    for member in z.infolist():
        if not (root / member.filename).resolve().is_relative_to(root):
            raise SystemExit("Unsafe archive member")
    z.extractall(root)
PY
  fi
  SOURCE="$(find "$STAGE/archive" -type d -name paperplot-skills | head -n 1)"
fi
[ -n "$SOURCE" ] && [ -f "$SOURCE/SKILL.md" ] || { echo "Skill source missing" >&2; exit 1; }
mkdir "$STAGE/candidate"
if [ "$PROFILE" = full ]; then
  cp -R "$SOURCE/." "$STAGE/candidate/"
else
  for item in SKILL.md README.md INSTALL.md USAGE.md agents references templates recipes environment.yml conda-osx-arm64.lock renv.lock requirements.lock; do
    [ -e "$SOURCE/$item" ] && cp -R "$SOURCE/$item" "$STAGE/candidate/"
  done
  mkdir "$STAGE/candidate/scripts"
  for script in paperplot-run paperplot_helpers.R validate-figure-output.R visual-qa-report.R visual-qa-rendered-image.py compare-old-new-figures.py family-qa-score.py vision-review-adapter.py run-template-recipe.R check-environment.R export-audit.py figure-project.R create-example-project.R bootstrap-environment.R install-self-test.R; do
    [ -f "$SOURCE/scripts/$script" ] || { echo "Missing runtime script: $script" >&2; exit 1; }
    cp "$SOURCE/scripts/$script" "$STAGE/candidate/scripts/"
  done
  cp -R "$SOURCE/scripts/lib" "$STAGE/candidate/scripts/"
fi
for path in SKILL.md recipes/recipe_manifest.csv scripts/paperplot_helpers.R scripts/lib/production-render.R scripts/lib/figure-project.R scripts/lib/recipe-contract.R; do
  [ -s "$STAGE/candidate/$path" ] || { echo "Invalid staged bundle: $path" >&2; exit 1; }
done
"$STAGE/candidate/scripts/paperplot-run" "$STAGE/candidate/scripts/check-environment.R" >/dev/null
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  mkdir -p "$BACKUP_ROOT"
  "$STAGE/candidate/scripts/paperplot-run" python -c 'import os,sys; assert os.stat(sys.argv[1]).st_dev == os.stat(sys.argv[2]).st_dev, "Backup and install must share a filesystem"' "$DEST_ROOT" "$BACKUP_ROOT"
  BACKUP="$BACKUP_ROOT/$SKILL_NAME.backup-$(date +%Y%m%d-%H%M%S)-$$"
  mv "$DEST" "$BACKUP"
fi
if ! mv "$STAGE/candidate" "$DEST"; then
  [ -z "$BACKUP" ] || mv "$BACKUP" "$DEST"
  exit 1
fi
SWITCHED=1
(cd "$STAGE" && PAPERPLOT_INSTALL_COMMIT="$COMMIT" PAPERPLOT_INSTALL_DIRTY="$DIRTY" "$DEST/scripts/paperplot-run" "$DEST/scripts/install-self-test.R")
COMPLETE=1
echo "Installed $SKILL_NAME ($PROFILE, ref $REF) to $DEST"
[ -z "$BACKUP" ] || echo "Previous installation retained at $BACKUP"
