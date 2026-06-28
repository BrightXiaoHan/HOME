#!/bin/bash

get_latest_stable_nodejs_version() {
    local url="https://nodejs.org/dist/index.json"
    local temp_file=$(mktemp)

    # Download the JSON data
    if ! curl -s "$url" -o "$temp_file"; then
        echo "Failed to retrieve the latest stable version of Node.js" >&2
        rm "$temp_file"
        return 1
    fi

    # Parse JSON and find the latest stable (LTS) version
    local latest_version=$(jq -r '
        map(select(.lts != false))
        | sort_by(.date)
        | reverse
        | .[0].version
    ' "$temp_file")

    rm "$temp_file"

    if [[ -n "$latest_version" ]]; then
        echo "$latest_version"
    else
        echo "Failed to parse the latest stable version of Node.js" >&2
        return 1
    fi
}