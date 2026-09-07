#!/bin/sh
cd "$(dirname "$0")/.." && exec luajit test/ui_smoke.lua
