#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

export PASS="testing"
export DB="$(mktemp)"
export N=0

source "${DIR}/keyvalstore.sh"

function store_retrieve_ok()
{
    local key="$1"
    local val="$2"

    store "$key" "$val"

    let N=N+1

    local result=$(
        test "$(retrieve "$key")" == "$val" \
            && echo "ok"                    \
            || echo "not ok"
    )

    echo "${result} ${N} - ${key}->${val}"
}

rm -f $DB

store_retrieve_ok 'a' 'b'

store_retrieve_ok 'a' 'c'

store_retrieve_ok '1' '2'

store_retrieve_ok '1' '3'

store_retrieve_ok '~!@#$%^&**(((()))_+=-`[]{}|\\:;"?/><,.' '0'

store_retrieve_ok '0' '~!@#$%^&**(((()))_+=-`[]{}|\\:;"?/><,.'

rm -f $DB

test $N -eq 6 && exit 0 || exit 1
