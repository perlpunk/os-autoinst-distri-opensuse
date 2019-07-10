#!/usr/bin/env bash

dir=$( dirname ${BASH_SOURCE[0]} )
source "$dir/test-simple.bash"
source "$dir/sqlite.bash"

declare DBFILE="$dir/movies.db"
declare SQLITE_SELECT_CMD=(sqlite3 --list --header $DBFILE)
declare output

#set -e

rm -f $DBFILE


function create-tables() {

    call-sqlite-file "$dir/init-tables.sql" "create tables"

    sqlite-select "SELECT * FROM movies ORDER BY mid"

    local expected=(
        "mid|name|year"
        "1|The Dead Dont Die|2019"
        "2|Night on Earth|1991"
        "3|Only Lovers Left Alive|2013"
        "4|Ed Wood|1994"
        "5|Sleepy Hollow|1999"
        "6|Edward Scissorhands|1990"
        "7|The Matrix|1999"
        "8|Amores Perros|2000"
    )
    cmp-array "select from movies" ${output[@]}
}

function test-alter-tables() {
    call-sqlite-file "$dir/alter-tables.sql" "alter tables"

    sqlite-select "SELECT * FROM movie ORDER BY mid LIMIT 1"
    local expected=(
        "mid|name|year|mtime"
        "1|The Dead Dont Die|2019|"
    )
    cmp-array "select from movie" ${output[@]}
}

function test-trigger() {
    echo 'UPDATE movie SET name="The Dead Don'"'"'t Die" WHERE mid=1' \
        | sqlite3 $DBFILE
    [[ $? -eq 0 ]] && pass "update" || fail "update"

    sqlite-select "SELECT * FROM movie WHERE mtime >= datetime('NOW', '-1 minute')"
    if [[ ${#output[*]} -eq 2 ]]; then
        pass "one updated row"
    else
        fail "one updated row"
    fi
}

function test-unique() {
    output="$(
        echo 'INSERT INTO director_movie (did, mid) VALUES (1,1)' | \
        sqlite3 $DBFILE 2>&1 \
    )"
    [[ $? -eq 1 ]] && pass "forbidden duplicate row" || fail "forbidden duplicate row"
    if [[ "$output" =~ UNIQUE ]]; then
        pass "Error message like expected"
    else
        fail "Error message like expected"
        diag "Got error message >>$output<<"
    fi

}

function test-foreign-key() {
    output="$(
        echo 'INSERT INTO director_movie (did, mid) VALUES (99,99)' | \
        sqlite3 --cmd "PRAGMA foreign_keys = ON" $DBFILE 2>&1 \
    )"
    [[ $? -eq 1 ]] && pass "foreign key" || fail "foreign key"
    if [[ "$output" =~ FOREIGN\ KEY ]]; then
        pass "Error message like expected"
    else
        fail "Error message like expected"
        diag "Got error message >>$output<<"
    fi

}

function test-view() {
    sqlite-select "SELECT * FROM cinema ORDER BY year, name LIMIT 6"

    local expected=(
        "name|year|directors"
        "Edward Scissorhands|1990|Tim Burton"
        "Night on Earth|1991|Jim Jarmusch"
        "Ed Wood|1994|Tim Burton"
        "Sleepy Hollow|1999|Tim Burton"
        "The Matrix|1999|Lana Wachowski+Lilly Wachowski"
        "Amores Perros|2000|Alejandro González Iñárritu"
    )
    cmp-array "select from cinema (view)" ${output[@]}
}

function test-rollback() {
    call-sqlite-file "$dir/rollback.sql" "savepoint & rollback"

    local expected=(
        "mid|name|year|mtime"
        "9|The Matrix Reloaded|2003|"
    )
    cmp-array "output savepoint & rollback ok" ${output[@]}
}

note "Testing in verbose mode"

create-tables

test-alter-tables

test-view

test-trigger

test-unique

test-foreign-key

test-rollback

done-testing
# alternatively at the beginning: plan-tests n

# test-simple will take care of the exit code
