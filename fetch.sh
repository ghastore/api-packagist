#!/bin/bash -e

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION.
# -------------------------------------------------------------------------------------------------------------------- #

# Action.
GIT_REPO="${1}"
GIT_USER="${2}"
GIT_EMAIL="${3}"
GIT_TOKEN="${4}"
API_URL_MAIN="${5}"
API_URL_REPO="${6}"
API_DIR="${7}"
API_VENDOR="${8}"
BOT_INFO="${9}"

# Vars.
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 (${BOT_INFO})"

# Apps.
curl="$( command -v curl )"
date="$( command -v date )"
git="$( command -v git )"
jq="$( command -v jq )"
mkdir="$( command -v mkdir )"

# Dirs.
d_src="/root/git/repo"

# Git.
${git} config --global user.name "${GIT_USER}"
${git} config --global user.email "${GIT_EMAIL}"
${git} config --global init.defaultBranch 'main'

# -------------------------------------------------------------------------------------------------------------------- #
# INITIALIZATION.
# -------------------------------------------------------------------------------------------------------------------- #

init() {
  ts="$( _timestamp )"
  clone
  pg_pkgs
  push
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: CLONE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

clone() {
  echo "--- [GIT] CLONE: ${GIT_REPO#https://}"

  local src="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO#https://}"
  ${git} clone "${src}" "${d_src}"

  echo "--- [GIT] LIST: '${d_src}'"
  ls -1 "${d_src}"
}

# -------------------------------------------------------------------------------------------------------------------- #
# API: PACKAGES.
# -------------------------------------------------------------------------------------------------------------------- #

pg_pkgs() {
  echo "--- [PACKAGIST] PACKAGES"
  _pushd "${d_src}" || exit 1

  local dir="${API_DIR}/${API_VENDOR}/packages"
  _mkdir "${dir}"

  local pkgs
  readarray -t pkgs < <( _curl "${API_URL_MAIN}/packages/list.json?vendor=${API_VENDOR}" | ${jq} -r '.packageNames[]' | awk -F '/' '{ print $2 }' )

  for pkg in "${pkgs[@]}"; do
    local api_main="${API_URL_MAIN}/packages/${API_VENDOR}/${pkg}.json"
    local api_repo="${API_URL_REPO}/p2/${API_VENDOR}/${pkg}.json"
    echo "Get '${api_main}'..." && _download "${api_main}" "${dir}/${pkg}.json"
    echo "Get '${api_repo}'..." && _download "${api_repo}" "${dir}/${pkg}.repo.json"
  done

  ${jq} -nc '$ARGS.positional' --args "${pkgs[@]}" > "${dir%/*}/packages.json"

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# GIT: PUSH API TO API STORE REPOSITORY.
# -------------------------------------------------------------------------------------------------------------------- #

push() {
  echo "--- [GIT] PUSH: '${d_src}' -> '${GIT_REPO#https://}'"
  _pushd "${d_src}" || exit 1

  # Commit build files & push.
  echo "Commit build files & push..."
  ${git} add . \
    && ${git} commit -a -m "API: ${ts}" \
    && ${git} push

  _popd || exit 1
}

# -------------------------------------------------------------------------------------------------------------------- #
# ------------------------------------------------< COMMON FUNCTIONS >------------------------------------------------ #
# -------------------------------------------------------------------------------------------------------------------- #

# Pushd.
_pushd() {
  command pushd "$@" > /dev/null || exit 1
}

# Popd.
_popd() {
  command popd > /dev/null || exit 1
}

# Timestamp.
_timestamp() {
  ${date} -u '+%Y-%m-%d %T'
}

# Make directory.
_mkdir() {
  [[ ! -d "${1}" ]] && ${mkdir} -p "${1}"
}

# cURL: Get Data.
_curl() {
  ${curl} -X GET \
    -A "${USER_AGENT}" -fsSL "${1}"
}

# cURL: Download data.
_download() {
  ${curl} -X GET \
    -A "${USER_AGENT}" -fsSL -o "${2}" "${1}"
}

# -------------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------------< INIT FUNCTIONS >------------------------------------------------- #
# -------------------------------------------------------------------------------------------------------------------- #

init "$@"; exit 0
