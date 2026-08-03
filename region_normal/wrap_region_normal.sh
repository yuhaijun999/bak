#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "[1/3] 获取 Store Map..."
./exec_get_store_map.sh

echo "[2/3] 获取 Region Map..."
./exec_get_region_map.sh

echo "[3/3] 检查 Region 状态..."
./exec_region_is_normal.sh --info

echo "执行完成。"
