#!/bin/bash

declare -i TESTNUM=0
declare -i RC=0

# trap code stolen from https://github.com/ingydotnet/test-more-bash
trap finish EXIT

function finish() {
    exit $RC
}

# Plan number of tests at the beginning
# plan-tests 23
function plan-tests() {
    local plan=$1
    echo "1..$plan"
}

# If you have no plan, call this function at the end of your tests
function done-testing() {
    echo "1..$TESTNUM"
}

# diag "Some message" "More messages"
# Will be printed to stderr prefixed with '#'
# It will always be visible
function diag() {
    local IFS=$'\n'
    local messages=($@)
    for i in ${messages[@]}; do
        echo "# $i" >&2
    done
}

# note "Some message" "More messages"
# Like diag, but goes to stdout and will only be visible in verbose mode,
# e.g. `prove -v`
function note() {
    local IFS=$'\n'
    local messages=($@)
    for i in ${messages[@]}; do
        echo "# $i"
    done
}

# pass "Some test description"
function pass() {
    local label=$1
    TESTNUM+=1
    echo ok $TESTNUM - $label
}

# fail "Some test description"
function fail() {
    local label=$1
    TESTNUM+=1
    echo not ok $TESTNUM - $label
    RC=1
}

function cmp-array() {
    if [[ $# -lt 2 ]]; then
        echo 'usage: cmp-array "message" ${array[@]}'
        exit 1
    fi
    local label="$1"
    shift
    local array=($@)

    local result=true

    if [[ ${#array[@]} -lt ${#expected[@]} ]]; then
        diag "Array has less elements (${#array[@]}) than expected (${#expected[@]})"
        fail "$label"
        note ${array[@]}
        return
    fi

    for i in ${!expected[@]}; do
        if [[ "${array[$i]}" == "${expected[$i]}" ]]; then
            true
        else
            diag "Array $i >>${array[$i]}<< does not match >>${expected[$i]}<<"
            result=false
        fi
    done

    if [[ ${#array[@]} -gt ${#expected[@]} ]]; then
        diag "Array has more elements (${#array[@]}) than expected (${#expected[@]})"
        fail "$label"
        note ${array[@]}
        return
    fi

    if $result; then
        pass "$label"
    else
        fail "$label"
    fi

}

