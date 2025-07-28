#!/bin/bash

load_env_and_validate() {
  local env_file=".env"
  local required_vars=("$@")

  if [[ ! -f "$env_file" ]]; then
    echo "❌ .env file not found. Aborting." >&2
    return 1
  fi

  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ || -z "$key" || -z "$value" ]] && continue
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    export "$key=$value"
  done < "$env_file"

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
      echo "❌ Missing required .env variable: $var" >&2
      return 1
    fi
  done

  echo "✅ Environment loaded and validated."
}
