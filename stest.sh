#!/bin/bash

##################### global options #########################
# file names
FILE_IN="in"
FILE_REF="ref"
FILE_OUT="out"
FILE_STDERR="stderr"
FILE_ERR="err"
FILE_CMD="cmd"

# colours
COLOR_FAIL='\033[0;31m' # red
COLOR_OK='\033[0;32m'   # green
NC='\033[0m'

# default options
DEFAULT_CMD=""
TEST_DIR=""
ACTION="TEST"

# fail counter
FAIL_COUNT=0

#################### helper functions ########################
clean() {
    DIR=$1
    for d in "${DIR}"/*/ ; do
        rm -f "$d/${FILE_OUT}" "$d/${FILE_STDERR}"
    done
}

print_ok_color() {
    echo -e "${COLOR_OK}${1}${NC}"
}

print_fail_color() {
    echo -e "${COLOR_FAIL}${1}${NC}"
}

expect_ok() {
    CURR_TEST="${1::-1}"
    CMD="$2"

    # run command
    if [ -f "${CURR_TEST}/${FILE_IN}" ]; then
        ${CMD} <"${CURR_TEST}/${FILE_IN}" >"${CURR_TEST}/${FILE_OUT}" 2>"${CURR_TEST}/${FILE_STDERR}"
    else
        ${CMD} >"${CURR_TEST}/${FILE_OUT}" 2>"${CURR_TEST}/${FILE_STDERR}"
    fi

    ERR_CODE="${?}"
    DIFF="$(diff "${CURR_TEST}"/${FILE_REF} "${CURR_TEST}"/${FILE_OUT})"

    if [ -z "${DIFF}" ] && [ "${ERR_CODE}" -eq 0 ]; then
        print_ok_color "[PASSED] ${CURR_TEST}"
    else
        FAIL_COUNT=$((FAIL_COUNT+1))

        print_fail_color "[FAILED] ${CURR_TEST}"

        # print command
        echo "${CMD} ${CURR_TEST}/${FILE_IN}"

        # print diff
        # TODO diff -U0 --label="" --label="" test/002-fail/ref test/002-fail/out
        #   show only differences
        echo "${DIFF}"
    fi
}

expect_err() {
    CURR_TEST="${1::-1}"
    CMD="$2"
    ERR_EXPECT="$3"

    # run command
    if [ -f "${CURR_TEST}/${FILE_IN}" ]; then
        ${CMD} <"${CURR_TEST}/${FILE_IN}" >"${CURR_TEST}/${FILE_OUT}" 2>"${CURR_TEST}/${FILE_STDERR}"
    else
        ${CMD} >"${CURR_TEST}/${FILE_OUT}" 2>"${CURR_TEST}/${FILE_STDERR}"
    fi

    ERR_CODE="${?}"

    if [ "${ERR_CODE}" -eq "${ERR_EXPECT}" ]; then
        print_ok_color "[PASSED] ${CURR_TEST}"
    else
        FAIL_COUNT=$(${FAIL_COUNT} + 1)

        print_fail_color "[FAILED] ${CURR_TEST}"

        echo "expected err: ${ERR_EXPECT}"
        echo "got: ${ERR_CODE}"

        # print command
        echo "${CMD} ${CURR_TEST}/${FILE_IN}"

        cat "${CURR_TEST}/${FILE_OUT}"
    fi
}

test() {
    DIR="$1"
    DEF_CMD="$2"

    for d in "${DIR}"/*/ ; do

        # if error file exists and is other than 0 we should test for expected error
        EXPECTED_ERR=0
        if [ -f "${d}${FILE_ERR}" ]; then
            EXPECTED_ERR=$(cat "${d}${FILE_ERR}")
        fi

        # if file with alternative command exists then we should use that
        CMD="${DEF_CMD}"
        if [ -f "${d}${FILE_CMD}" ]; then
            CMD=$(cat "${d}${FILE_CMD}")
        fi

        if [ "${EXPECTED_ERR}" -ne 0 ]; then
            expect_err "${d}" "${CMD}" "${EXPECTED_ERR}"
        else
            expect_ok "${d}" "${CMD}"
        fi

    done
}

print_final_score() {
    if [ "${FAIL_COUNT}" -eq 0 ]; then
        print_ok_color "ALL TESTS PASSED"
    else
        print_fail_color "${FAIL_COUNT} TESTS FAILED"
    fi
}

###################### argument parsing #########################
while getopts "ce:d:" opt; do
    case ${opt} in
        c )
            ACTION="CLEAN"
            ;;
        e )
            DEFAULT_CMD=$OPTARG
            ;;
        d )
            TEST_DIR=$OPTARG
            ;;
        \? )
            echo "Usage: stest.sh [-c] [-e \"default_command\"] [-d \"directory\"]"
            ;;
    esac
done
shift $((OPTIND -1))

if [ -z "${TEST_DIR}" ]; then
    echo "Usage: stest.sh [-c] [-e \"default_command\"] [-d \"directory\"]"
    exit
fi

############################ MAIN ################################
if [ "${ACTION}" = "CLEAN" ]; then
    clean "${TEST_DIR}"
    exit
else
    test "${TEST_DIR}" "${DEFAULT_CMD}"
    print_final_score
fi
