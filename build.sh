#!/usr/bin/env bash
# build.sh — limpia, compila, fija header y lanza BGB
# Uso: ./build.sh

set -euo pipefail

echo "==> make clean"
make clean

echo "==> make"
make

echo "==> rgbfix -v -p 0xFF game.gb"
rgbfix -v -p 0xFF game.gb

echo "==> gbt_bgb game.gb"
gbt_bgb game.gb
