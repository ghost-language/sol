#!/bin/bash
# Sets up the Ghost + Lumen toolchain that Sol is built on. Neither is
# published anywhere Claude Code can install from, so this clones both as
# sibling checkouts (Lumen's go.mod points a replace directive at "../ghost",
# so they have to sit next to each other), installs the SDL2 development
# headers Lumen needs to build (it links SDL2 through cgo), and builds both
# CLIs. "sol" itself is Ghost source with no build step of its own; running
# it is `lumen path/to/sol`.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": false}'

WORKSPACE="$HOME/ghostlang"
mkdir -p "$WORKSPACE"

clone_or_update() {
  local repo="$1" dir="$2"

  if [ -d "$dir/.git" ]; then
    git -C "$dir" fetch --depth 1 origin
    git -C "$dir" reset --hard FETCH_HEAD
  else
    git clone --depth 1 "https://github.com/ghost-language/$repo" "$dir"
  fi
}

clone_or_update ghost "$WORKSPACE/ghost"
clone_or_update lumen "$WORKSPACE/lumen"

if ! pkg-config --exists sdl2 2>/dev/null; then
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev
fi

(cd "$WORKSPACE/lumen" && make build)

mkdir -p "$HOME/.local/bin"
ln -sf "$WORKSPACE/lumen/dist/lumen" "$HOME/.local/bin/lumen"

(cd "$WORKSPACE/ghost" && go build -trimpath -o dist/ghost ./cmd)
ln -sf "$WORKSPACE/ghost/dist/ghost" "$HOME/.local/bin/ghost"

{
  echo "export PATH=\"$HOME/.local/bin:\$PATH\""
  echo "export SOL_GHOSTLANG_WORKSPACE=\"$WORKSPACE\""
} >> "$CLAUDE_ENV_FILE"
