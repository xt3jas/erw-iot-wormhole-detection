#!/bin/zsh
set -e

port="${1:-47001}"
if [[ ! "$port" == <-> ]] || (( port < 1 || port > 65535 )); then
    print -u2 "Port must be an integer from 1 to 65535."
    exit 2
fi

project_dir="$(cd "$(dirname "$0")" && pwd)"
matlab_bin="${MATLAB_BIN:-/Applications/MATLAB_R2026b.app/bin/matlab}"
exec "$matlab_bin" -batch \
    "addpath('$project_dir/matlab'); erw_service($port)"
