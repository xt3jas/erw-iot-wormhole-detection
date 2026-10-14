#!/bin/zsh
set -e
project_dir="$(cd "$(dirname "$0")" && pwd)"
matlab_bin="${MATLAB_BIN:-/Applications/MATLAB_R2026b.app/bin/matlab}"
run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
output_dir="$project_dir/demo_output/$run_id"
matlab_expr="addpath('$project_dir/matlab'); evalc(\"erw_selftest; erw_run_demo('$output_dir', 42, 100, 'mixed')\"); erw_mvp_report('$output_dir')"
"$matlab_bin" -batch "$matlab_expr"
