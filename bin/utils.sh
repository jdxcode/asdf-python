#!/usr/bin/env bash

python_bin() {
  echo "$RTX_INSTALL_PATH/bin/python"
}

echoerr() {
  echo "$*" >&2
}

ensure_python_build_installed() {
  if [ ! -f "$(python_build_path)" ]; then
    download_python_build
  fi
}

download_python_build() {
  echo "Downloading python-build..." >&2
  local pyenv_url="${RTX_PYENV_REPO:-https://github.com/pyenv/pyenv.git}"
  git clone $pyenv_url "$(pyenv_path)"
}

python_build_path() {
  echo "$(pyenv_path)/plugins/python-build/bin/python-build"
}

update_python_build() {
  cd "$(pyenv_path)" && git fetch && git reset --hard origin/master > /dev/null 2>&1
}

pyenv_path() {
  echo "$(dirname $(dirname $0))/pyenv"
}

pyenv_update_timestamp_path() {
  echo "$(dirname $(dirname "$0"))/pyenv_last_update"
}

pyenv_should_update() {
  update_timeout=3600
  update_timestamp_path=$(pyenv_update_timestamp_path)

  if [ ! -f "$update_timestamp_path" ]; then
    return 0
  fi

  last_update=$(cat "$update_timestamp_path")
  current_timestamp=$(date +%s)
  invalidated_at=$(($last_update + $update_timeout))

  [ $invalidated_at -lt $current_timestamp ]
}

install_or_update_python_build() {
  if [ ! -f "$(python_build_path)" ]; then
    download_python_build
  elif pyenv_should_update; then
    update_python_build
    date +%s > "$(pyenv_update_timestamp_path)"
  fi
}

get_venv() {
  venv="$(eval "echo ${RTX_TOOL_OPTS__VIRTUALENV:-}")"
  if [ "$venv" = "" ]; then
    return
  fi
  if [[ "$venv" != /* ]] && [[ -n "${RTX_PROJECT_ROOT:-}" ]]; then
    venv="${RTX_PROJECT_ROOT:-}/$venv"
  fi
  if [[ ! -d "$venv" ]] || [[ "Python ${RTX_INSTALL_VERSION}" != "$("$venv"/bin/python -V)" ]]; then
    echoerr "rtx-python: setting up virtualenv at $venv"
    "$(python_bin)" -m venv --clear "$venv"
  fi
  echo "$venv"
}
