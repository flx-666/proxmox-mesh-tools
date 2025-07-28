#!/bin/bash

log_info()  { echo -e "🟢 [INFO] $1"; }
log_warn()  { echo -e "🟡 [WARN] $1"; }
log_error() { echo -e "🔴 [ERROR] $1" >&2; }
log_debug() { [[ "$DEBUG" == "true" ]] && echo -e "🔍 [DEBUG] $1"; }
