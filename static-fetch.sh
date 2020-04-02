#!/usr/bin/env bash

#
# Constants
#

FOLIUM_REV="v0.10.1"
BASE_DIR="static"

#
# Functions
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
    local -r url="$1"

    local -r dp="$(dirname "$(strip_protocol "${url}")")"
    local -r full_dp="${base_dir}/${dp}"

    echo "${full_dp}"
}

function get_full_filepath_from_url {
    local -r url="$1"

    local -r full_dp="$(get_full_dirpath_from_url "${url}")"
    local -r bn="$(basename "${url}")"
    local -r full_fp="${full_dp}/${bn}"

    echo "${full_fp}"
}

function download_url_impl {
    local -r base_dir=$1
    local -r url=$2

    local -r full_fp="$(get_full_filepath_from_url "${url}")"

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
            full_fp="$(get_full_filepath_from_url "${url}")"
            rel_urls="$(rg "url\('(.+?)'\)" -o -r "\$1" --no-column --no-filename -N -U -- "${full_fp}")"

            for rel_url in ${rel_urls}; do
                inner_url="$(resolve_url "${url}" "${rel_url}")"
                download_url_impl "${base_dir}" "${inner_url}"
            done
        fi
    done
}

#
# Main
#

# We will assume that if `folium` directory is present, we have already git cloned it
if [[ ! -d "folium" ]]; then
    git clone https://github.com/python-visualization/folium.git
fi

# Checkout to the right rev
(cd folium && git fetch -p && git checkout "${FOLIUM_REV}")

# All other JavascriptLink
download_urls "${BASE_DIR}" "$(rg "JavascriptLink\(\s*['\"](.+?)['\"]\)" -o -r "\$1" --no-column --no-filename -N -U -- folium/ | sort -h | uniq)" no

# _default_js for folium
download_urls "${BASE_DIR}" "$(rg "['\"](http[s]://.+?\.js)['\"]" -o -r "\$1" --no-column --no-filename -N -U -- folium/folium/folium.py | sort -h | uniq)" no

# All other CssLink
download_urls "${BASE_DIR}" "$(rg "CssLink\(\s*['\"](.+?)['\"]\)" -o -r "\$1" --no-column --no-filename -N -U -- folium/ | sort -h | uniq)" yes

# _default_css for folium
download_urls "${BASE_DIR}" "$(rg "['\"](http[s]://.+?\.css)['\"]" -o -r "\$1" --no-column --no-filename -N -U -- folium/folium/folium.py | sort -h | uniq)" yes

