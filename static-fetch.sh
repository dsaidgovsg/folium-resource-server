#!/usr/bin/env bash
set -euo pipefail

#
# Constants
#

FOLIUM_REV="v0.10.1"
BASE_DIR="static"  # To keep all the downloaded resources for hosting
EXT_DIR="external"  # To keep the resource mapping config for external usage
EXT_JS_CONF_FILENAME="folium-js.json"
EXT_CSS_CONF_FILENAME="folium-css.json"

#
# Resource fetching functions
#

function strip_protocol {
  local -r url="$1"
  local mod_url

  mod_url="${url/https:\/\//}"
  mod_url="${mod_url/http:\/\//}"

  echo "${mod_url}"
}

function resolve_url {
  local -r base_url="$1"
  local -r relative_url="$2"

  local base_dp; base_dp="$(dirname "${base_url}")"
  local mod_relative_url; mod_relative_url="${relative_url}"

  # For simplicity, we assume the ../ only exists on the left until a non-../ is found
  if [[ "${mod_relative_url}" == "../"* ]]; then
    base_dp="$(dirname "${base_dp}")"
    mod_relative_url="${mod_relative_url:3}"  # Substring to strip off the ../
  fi

  echo "${base_dp}/${mod_relative_url}"
}

function get_full_dirpath_from_url {
  local -r base_dir="$1"
  local -r url="$2"

  local -r dp="$(dirname "$(strip_protocol "${url}")")"

  if [[ "${base_dir}" == "" ]]; then
    # Special case not to append base if empty
    echo "${dp}"
  else
    echo "${base_dir}/${dp}"
  fi
}

function get_full_filepath_from_url {
  local -r base_dir="$1"
  local -r url="$2"

  local -r full_dp="$(get_full_dirpath_from_url "${base_dir}" "${url}")"
  local -r bn="$(basename "${url}")"
  local -r full_fp="${full_dp}/${bn}"

  echo "${full_fp}"
}

function download_url_impl {
  local -r base_dir=$1
  local -r url=$2

  local -r full_fp="$(get_full_filepath_from_url "${base_dir}" "${url}")"

  # Only download file if remote file is newer
  local zflag
  if [[ -e "${full_fp}" ]]; then
    zflag=(-z "${full_fp}")
  else
    zflag=()
  fi

  curl --create-dirs -sL -o "${full_fp}" "${zflag[@]}" "${url}"
  echo "${url} -> ${full_fp}"
}

function download_urls {
  # Takes in a base directory to save into, and all the URLs to download
  # The directory hierarchy to place the resource to download follows the URL
  local -r base_dir="$1"
  local -r urls="$2"
  local -r find_css_urls="$3"  # For CSS files only

  local full_fp
  local rel_urls
  local inner_url

  for url in ${urls}; do
    download_url_impl "${base_dir}" "${url}"
    
    # Additional step for CSS files only
    # Need to find the inner external resources the CSS uses and save relative to its path
    if [[ "${find_css_urls}" == "yes" ]]; then
      full_fp="$(get_full_filepath_from_url "${base_dir}" "${url}")"

      # rg returns 1 when it fails to find a match, which is okay here if the CSS doesn't have
      # additional resources
      rel_urls="$(rg "url\('(.+?)'\)" -o -r "\$1" --no-column --no-filename -N -U -- "${full_fp}" || true)"

      for rel_url in ${rel_urls}; do
        inner_url="$(resolve_url "${url}" "${rel_url}")"
        download_url_impl "${base_dir}" "${inner_url}"
      done
    fi
  done
}

#
# JSON generation functions
#

function join_by { local IFS="$1"; shift; echo "$*"; }

function form_url_list {
  local -r urls="$1"
  for url in ${urls}; do
    bn="$(basename "${url}")"
    echo "\"${bn}\":\"$(get_full_dirpath_from_url "" "${url}")/${bn}\""
  done
}

function generate_url_json {
  local -r urls="$1"
  # jq automatically removes duplicate keys if any
  # Also word splitting is required here so we ignore shellcheck SC2046
  echo "{$(join_by "," $(form_url_list "${urls}"))}" | jq -M -r .
}

#
# Main
#

download_static=yes
generate_conf=yes
delete_static=no
delete_conf=no

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h|--help)
    echo "$0 - Fetch folium external resources and generate config"
    echo " "
    echo "$0 [OPTIONS] "
    echo " "
    echo "OPTIONS:"
    echo "  --no-static      Do not download external folium static resources"
    echo "  --no-conf        Do not generate external resource configurations"
    echo "  --delete-static  Delete all external folium static resources first"
    echo "  --delete-conf    Delete all external resource configurations first"
    exit 0
    ;;
  --no-static)
    download_static=no
    shift
    ;;
  --no-conf)
    generate_conf=no
    shift
    ;;
  --delete-static)
    delete_static=yes
    shift
    ;;
  --delete-conf)
    delete_conf=yes
    shift
    ;;
  *)
    >&2 echo "Unknown flag \"$1\" provided!"
    exit 1
    ;;
  esac
done

# Null case where all actions to take are disabled
if [[ "${download_static}" == "no" && "${generate_conf}" == "no" && "${delete_static}" == "no" && "${delete_conf}" == "no" ]]; then
  echo "DONE! No actions required for the script!"
  exit 0
fi

if [[ "${delete_static}" == "yes" ]]; then
  rm -rf "${BASE_DIR:?}/"
fi

if [[ "${delete_conf}" == "yes" ]]; then
  rm -rf "${EXT_DIR:?}/"
fi

# We will assume that if `folium` directory is present, we have already git cloned it
if [[ "${download_static}" == "yes" || "${generate_conf}" == "yes" ]]; then
  if [[ ! -d "folium" ]]; then
    git clone https://github.com/python-visualization/folium.git
  fi

  # Checkout to the right rev
  (cd folium && git fetch -p && git checkout "${FOLIUM_REV}")

  # All other JavascriptLink
  js_urls="$(rg "JavascriptLink\(\s*['\"](.+?)['\"]\)" -o -r "\$1" --no-column --no-filename -N -U -- folium/ | sort -h | uniq)"
  # _default_js for folium
  def_js_urls="$(rg "['\"](http[s]://.+?\.js)['\"]" -o -r "\$1" --no-column --no-filename -N -U -- folium/folium/folium.py | sort -h | uniq)"
  # All other CssLink
  css_urls="$(rg "CssLink\(\s*['\"](.+?)['\"]\)" -o -r "\$1" --no-column --no-filename -N -U -- folium/ | sort -h | uniq)"
  # _default_css for folium
  def_css_urls="$(rg "['\"](http[s]://.+?\.css)['\"]" -o -r "\$1" --no-column --no-filename -N -U -- folium/folium/folium.py | sort -h | uniq)"

  # Download external static resources 
  if [[ "${download_static}" == "yes" ]]; then
    echo "Downloading JS resources..."
    download_urls "${BASE_DIR}" "${js_urls}" no
    download_urls "${BASE_DIR}" "${def_js_urls}" no

    echo "Downloading CSS resources..."
    download_urls "${BASE_DIR}" "${css_urls}" yes
    download_urls "${BASE_DIR}" "${def_css_urls}" yes
  fi

  # Generate JSON config for all JS and CSS resources
  if [[ "${generate_conf}" == "yes" ]]; then
    echo "Writing external configuration files..."
    mkdir -p "${EXT_DIR}"
    all_js_urls="${js_urls} ${def_js_urls}"
    generate_url_json "${all_js_urls}" > "${EXT_DIR}/${EXT_JS_CONF_FILENAME}"

    all_css_urls="${css_urls} ${def_css_urls}"
    generate_url_json "${all_css_urls}" > "${EXT_DIR}/${EXT_CSS_CONF_FILENAME}"
  fi
fi

echo "DONE!"
