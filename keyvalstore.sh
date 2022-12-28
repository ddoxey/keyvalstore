#!/bin/bash
: '
: This is a light weight private key value store for command line use.
:
: https://github.com/ddoxey/keyvalstore
'
export DB
export PASS
export AWK=$(which awk)
export SED=$(which sed)
export MD5SUM=$(which md5sum || which md5)
export OPENSSL=$(which openssl)
export MAC="$(uname | $AWK '{if (tolower($1) ~ /darwin/) {print "TRUE"}}')"


: '
: Print the given message to stderr.
'
function err()
{
    echo "$@" >&2 && return 1
}

: '
: Compute an MD5 hash for the given value.
'
function md5()
{
    echo "$@" | $MD5SUM | $AWK '{print $1}'
}

: '
: Encrypt the given string.
'
function enc()
{
    if [[ $# -eq 0 ]]; then return 1; fi

    echo "$@" | $OPENSSL aes-256-cbc -pass env:PASS -e -a -A 2>/dev/null
}

: '
: Decrypt the given string.
'
function dec()
{
    if [[ $# -eq 0 ]]; then return 1; fi

    echo "$@" | $OPENSSL aes-256-cbc -pass env:PASS -d -a -A 2>/dev/null
}

: '
: Create the minimal DB file if absent.
'
function initdb()
{
    if [[ -z $DB ]]; then return err "DB not defined"; fi
    if [[ -z $PASS ]]; then return err "PASS not defined"; fi

    touch "$DB" && store "_password_" "$PASS" && return 0

    return 1
}

: '
: Print a list of keys.
'
function enumerate()
{
    local keys="$(retrieve "_keys_")"

    $AWK -F'|' '{
        for (i = 1; i < NF; i++)
            if ($i && $i != "_password_")
                print $i
    }' <<< "$keys"
}

: '
: Retrieve the decrypted value for the given key.
'
function retrieve()
{
    if [[ ! -e "$DB" ]]; then initdb || return 1; fi

    local key="$($SED 's/|//g' <<< "$1")"
    local hsh="$(md5 "$key")"

    local line_n=$(grep -n "^${hsh}[|]" "$DB" | $AWK -F: '{print $1}')

    if [[ -n $line_n ]]
    then
        dec "$($SED -n "${line_n}p" "$DB" | $AWK -F'|' '{print $2}')"
    fi
}

: '
: Store the given value for the given key.
'
function store()
{
    if [[ ! -e "$DB" ]]; then initdb || return 1; fi

    local key="$($SED 's/|//g' <<< "$1")"
    local val="$(enc "$2")"
    local hsh="$(md5 "$key")"

    if [[ "$key" != "_keys_" ]]
    then
        local keys="$(retrieve "_keys_")"

        if [[ -z $keys ]]; then keys="|"; fi

        if [[ ! "$keys" =~ "|${key}|" ]]
        then
            keys="${keys}${key}|"

            store "_keys_" "$keys"
        fi
    fi

    local line_n=$(grep -n "^${hsh}[|]" "$DB" | $AWK -F: '{print $1}')

    if [[ -n $line_n ]]
    then
        # update
        if [[ -n $MAC ]]
        then
            $SED -i '' "${line_n}s:^${hsh}[|].*:${hsh}|${val}:" "$DB"
        else
            $SED -i "${line_n}s:^${hsh}[|].*:${hsh}|${val}:" "$DB"
        fi
    else
        # add
        echo "${hsh}|${val}" >> "$DB"
    fi
}

: '
: Verify
'
function run()
{
    local key="$1"
    local val="$2"

    for dependency in AWK SED OPENSSL MD5SUM
    do
        if [[ -n ${!dependency} ]]; then continue; fi

        return $(err "Unable to locate: $(tr 'A-Z' 'a-z' <<< "$dependency")")
    done

    if [[ "$key" == "-h" ]]
    then
        return $(err "USAGE: $(basename "$0") [<key> [<val>]]")
    fi

    DB="${HOME}/.$($AWK 'tolower($0)' <<< "$(basename "$0")")-kv-db"

    if [[ -z $PASS ]]
    then
        echo -n "password: "
        read -s PASS
    fi

    local expect="$(retrieve "_password_")"

    if [[ -n $expect ]] && [[ "$PASS" != "$expect" ]]
    then
        return $(err "access denied")
    fi

    echo -ne '\b\b\b\b\b\b\b\b\b\b'
    echo -ne '          '
    echo -ne '\b\b\b\b\b\b\b\b\b\b'

    if [[ -z $key ]]; then enumerate && return 0; fi

    if [[ -z $val ]]
    then
        retrieve "$key"
    else
        store "$key" "$val"
    fi
}


if [[ $(caller | $AWK '{print $1}') -eq 0 ]]; then run "$@"; fi
