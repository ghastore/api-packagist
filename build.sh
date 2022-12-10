#!/bin/bash -e

# -------------------------------------------------------------------------------------------------------------------- #
# CONFIGURATION.
# -------------------------------------------------------------------------------------------------------------------- #

# Vars.
GIT_REPO="${1}"
GIT_USER="${2}"
GIT_EMAIL="${3}"
GIT_TOKEN="${4}"
API_DIR="${5}"
API_VENDOR="${6}"
BOT_INFO="${7}"
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
  clone \
    && api_pkgs \
    && push
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

api_pkgs() {
  echo "--- [PACKAGIST] PACKAGES"
  #_pushd "${d_src}" || exit 1

  local dir; dir="${API_DIR}/${API_VENDOR}/packages"
  [[ ! -d "${dir}" ]] && _mkdir "${dir}"

  local pkgs
  readarray -t pkgs < <( _curl "https://packagist.org/packages/list.json?vendor=${API_VENDOR}" | ${jq} -r '.packageNames[]' )

  for pkg in "${pkgs[@]}"; do
    local name; name="$( echo "${pkg}" | awk -F '[/]' '{ print $2 }' )"
    _download "https://packagist.org/packages/${pkg}.json" "${dir}/${name}.json"
    _download "https://repo.packagist.org/p2/${pkg}.json" "${dir}/${name}.repo.json"
  done

  ${jq} -nc '$ARGS.positional' --args "${pkgs[@]}" > "${dir}/_all.json"

  #_popd || exit 1
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
  ${mkdir} -p "${1}"
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
