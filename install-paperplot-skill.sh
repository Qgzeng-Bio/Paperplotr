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
  exit 1
}

tmp="${TMPDIR:-/tmp}/paperplot-skill-install.$$"
archive="${tmp}/repo.zip"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

if [ -e "$DEST" ]; then
  if [ "${PAPERPLOT_OVERWRITE:-0}" = "1" ]; then
    rm -rf "$DEST"
  else
    echo "Destination already exists: $DEST" >&2
    echo "Set PAPERPLOT_OVERWRITE=1 to replace it." >&2
    exit 1
  fi
fi

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
case "$PROFILE" in
  runtime)
    mkdir -p "$DEST"
    for item in SKILL.md agents references templates; do
      if [ -e "${skill_dir}/${item}" ]; then
        cp -R "${skill_dir}/${item}" "$DEST/"
      fi
    done
    mkdir -p "$DEST/scripts"
    for script in paperplot_helpers.R validate-figure-output.R visual-qa-report.R visual-qa-rendered-image.py compare-old-new-figures.py; do
      if [ -e "${skill_dir}/scripts/${script}" ]; then
        cp "${skill_dir}/scripts/${script}" "$DEST/scripts/"
      fi
    done
    if [ -d "${skill_dir}/scripts/lib" ]; then
      cp -R "${skill_dir}/scripts/lib" "$DEST/scripts/"
    fi
    ;;
  full)
    cp -R "$skill_dir" "$DEST"
    ;;
  *)
    echo "Unknown PAPERPLOT_PROFILE: $PROFILE" >&2
    echo "Use PAPERPLOT_PROFILE=runtime or PAPERPLOT_PROFILE=full." >&2
    exit 1
    ;;
esac

echo "Installed ${SKILL_NAME} (${PROFILE}) to ${DEST}"
echo "Restart Codex to pick up the new skill."
