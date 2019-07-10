#!/bin/bash

function sqlite-select() {
    local select=$1
    IFS=$'\n' output=( $(echo "$select" | ${SQLITE_SELECT_CMD[@]} ) )
}

function call-sqlite-file() {
    local file=$1
    local label=$2

    IFS=$'\n' output=( $( ${SQLITE_SELECT_CMD[@]} < $file ) )
    if [[ $? -ne 0 ]]; then
        fail 0 "$label"
        exit 1
    else
        pass "$label"
    fi
}
