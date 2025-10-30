#!/usr/bin/env bash
# build.sh — limpia, compila, fija header y lanza BGB
# Uso: ./build.sh

set -euo pipefail

echo "==> make clean"
make clean

echo "==> make"
make

echo "==> rgbfix -v -p 0xFF CromieGame.gb"
rgbfix -v -p 0xFF CromieGame.gb

echo "==> gbt_bgb CromieGame.gb"
gbt_bgb CromieGame.gb
