#!/usr/bin/env sh
set -eu

OWNER="${PAPERPLOT_OWNER:-Qgzeng-Bio}"
REPO="${PAPERPLOT_REPO:-Paperplotr}"
REF="${PAPERPLOT_REF:-main}"
SKILL_PATH="${PAPERPLOT_SKILL_PATH:-paperplot-skills}"
SKILL_NAME="${PAPERPLOT_SKILL_NAME:-paperplot-skills}"
PROFILE="${PAPERPLOT_PROFILE:-runtime}"
DEST_ROOT="${PAPERPLOT_DEST:-${CODEX_HOME:-$HOME/.codex}/skills}"
DEST="${DEST_ROOT}/${SKILL_NAME}"

case "$SKILL_NAME" in
  ""|.|..|*/*) echo "PAPERPLOT_SKILL_NAME must be one directory name." >&2; exit 1 ;;
esac

download_url() {
  url="$1"
  out="$2"

  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$url" -o "$out"; then
      return 0
    fi
    echo "curl download failed; trying wget..." >&2
  fi

  if command -v wget >/dev/null 2>&1; then
    if wget -q -O "$out" "$url"; then
      return 0
    fi
  fi

  echo "Could not download $url. Install curl or wget and try again." >&2
  return 1
}

tmp="${TMPDIR:-/tmp}/paperplot-skill-install.$$"
archive="${tmp}/repo.zip"
stage=""
backup=""
cleanup() {
  status="${1:-0}"
  trap - 0 HUP INT TERM
  if [ -n "$backup" ] && [ -e "$backup" ] && [ ! -e "$DEST" ]; then
    if mv "$backup" "$DEST"; then
      echo "Restored previous installation after an interrupted switch: $DEST" >&2
      backup=""
    else
      echo "Automatic restore failed; previous installation remains at: $backup" >&2
    fi
  fi
  if [ -n "$stage" ] && [ -e "$stage" ]; then
    rm -rf "$stage"
  fi
  rm -rf "$tmp"
  exit "$status"
}
trap 'cleanup $?' 0 HUP INT TERM

if [ -e "$DEST" ] && [ "${PAPERPLOT_OVERWRITE:-0}" != "1" ]; then
  echo "Destination already exists: $DEST" >&2
  echo "Set PAPERPLOT_OVERWRITE=1 to replace it transactionally." >&2
  exit 1
fi

mkdir -p "$tmp"
url="https://codeload.github.com/${OWNER}/${REPO}/zip/${REF}"
echo "Downloading ${OWNER}/${REPO}@${REF}..."
download_url "$url" "$archive"

if command -v unzip >/dev/null 2>&1; then
  unzip -q "$archive" -d "$tmp"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$archive" "$tmp" <<'PY'
import sys
import zipfile

archive, dest = sys.argv[1:3]
with zipfile.ZipFile(archive) as zf:
    zf.extractall(dest)
PY
else
  echo "Missing extractor: install unzip or python3." >&2
  exit 1
fi

skill_dir="$(find "$tmp" -type d -path "*/${SKILL_PATH}" | head -n 1)"
if [ -z "$skill_dir" ] || [ ! -f "${skill_dir}/SKILL.md" ]; then
  echo "Could not find ${SKILL_PATH}/SKILL.md in downloaded archive." >&2
  exit 1
fi

mkdir -p "$DEST_ROOT"
stage="${DEST_ROOT}/.${SKILL_NAME}.install.$$"
backup="${DEST_ROOT}/.${SKILL_NAME}.backup.$$"
if [ -e "$stage" ] || [ -e "$backup" ]; then
  echo "Transactional staging path already exists; retry the install: $stage or $backup" >&2
  exit 1
fi
mkdir "$stage"

case "$PROFILE" in
  runtime)
    for item in SKILL.md agents references templates; do
      if [ -e "${skill_dir}/${item}" ]; then
        cp -R "${skill_dir}/${item}" "$stage/"
      fi
    done
    mkdir -p "$stage/scripts"
    for script in paperplot_helpers.R validate-figure-output.R visual-qa-report.R visual-qa-rendered-image.py compare-old-new-figures.py; do
      if [ -e "${skill_dir}/scripts/${script}" ]; then
        cp "${skill_dir}/scripts/${script}" "$stage/scripts/"
      fi
    done
    if [ -d "${skill_dir}/scripts/lib" ]; then
      cp -R "${skill_dir}/scripts/lib" "$stage/scripts/"
    fi
    ;;
  full)
    cp -R "${skill_dir}/." "$stage/"
    ;;
  *)
    echo "Unknown PAPERPLOT_PROFILE: $PROFILE" >&2
    echo "Use PAPERPLOT_PROFILE=runtime or PAPERPLOT_PROFILE=full." >&2
    exit 1
    ;;
esac

for required in \
  SKILL.md \
  scripts/paperplot_helpers.R \
  scripts/validate-figure-output.R \
  scripts/visual-qa-rendered-image.py \
  scripts/compare-old-new-figures.py \
  scripts/lib/contract-parsers.R \
  references/journal-specs-matrix.md \
  references/bioinformatics-figure-validation.md
do
  if [ ! -f "${stage}/${required}" ]; then
    echo "Staged profile is incomplete; missing ${stage}/${required}" >&2
    exit 1
  fi
done

if [ -e "$DEST" ]; then
  mv "$DEST" "$backup"
fi
if ! mv "$stage" "$DEST"; then
  echo "Could not activate staged installation; restoring the previous runtime." >&2
  exit 1
fi
stage=""
if [ -n "$backup" ] && [ -e "$backup" ]; then
  rm -rf "$backup"
fi
backup=""

echo "Installed ${SKILL_NAME} (${PROFILE}) to ${DEST}"
echo "Restart Codex to pick up the new skill."
