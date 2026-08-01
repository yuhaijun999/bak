#!/usr/bin/env bash

set -euo pipefail

echo "[1/3] 获取 Store Map..."
./exec_get_store_map.sh

echo "[2/3] 获取 Region Map..."
./exec_get_region_map.sh

echo "[3/3] 比对 Region Leader..."
./exec_compare_region_leader_match.sh --info

echo "执行完成。"
