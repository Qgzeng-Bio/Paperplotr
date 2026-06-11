#!/usr/bin/env sh
set -eu

OWNER="${PAPERPLOT_OWNER:-Qgzeng-Bio}"
REPO="${PAPERPLOT_REPO:-Paperplotr}"
REF="${PAPERPLOT_REF:-portability-linux-fixes}"
SKILL_PATH="${PAPERPLOT_SKILL_PATH:-paperplot-skills}"
SKILL_NAME="${PAPERPLOT_SKILL_NAME:-paperplot-skills}"
PROFILE="${PAPERPLOT_PROFILE:-runtime}"
DEST_ROOT="${PAPERPLOT_DEST:-${CODEX_HOME:-$HOME/.codex}/skills}"
DEST="${DEST_ROOT}/${SKILL_NAME}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd curl

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
curl -fsSL "$url" -o "$archive"

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
    for item in SKILL.md agents scripts references templates; do
      if [ -e "${skill_dir}/${item}" ]; then
        cp -R "${skill_dir}/${item}" "$DEST/"
      fi
    done
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
