#!/bin/bash
# cstester.sh -- created 2011-01-06, <+NAME+>
# @Last Change: 24-Dez-2004.
# @Revision:    0.0

SOLUTION_NUMBER=17
SOLUTIONS_DIR=solutions

RESULTS_DIR=results
RESULTS_FILE=${RESULTS_DIR}/all_results.txt

TESTS_DIR=tests
TESTS_DESC_FILE=${TESTS_DIR}/17_tests.desc

CS_COMPILER=gmcs
CS_COMPILER_OPTS=

MONO_CMD=mono

DIFF_CMD=diff
DIFF_OPTS=

# Put here something if you want to skip compilation
# or leave empty if you want to compile all the sources
SKIP_COMPILATION=

function prepareInfrastructure() {
    [ ! -d "$TESTS_DIR" ] && echo "Directory $TESTS_DIR is missing !"

    [ -d "$RESULTS_DIR" ] && rm -rf "$RESULTS_DIR"
    mkdir "$RESULTS_DIR"

    [ ! -d "$SOLUTIONS_DIR" ] && mkdir "$SOLUTIONS_DIR"
}

function prepareSolutions() {
    L_ZIP=$1

    cp "${L_ZIP}" "${SOLUTIONS_DIR}/"
    
    (
        cd "$SOLUTIONS_DIR" 
        unzip "${L_ZIP}"
        rm -f "${L_ZIP}"
    )
}

function testSolutions() {
    SOLUTION_NUM=$1

    echo "Testing num. $SOLUTION_NUM"

    find "$SOLUTIONS_DIR/" -maxdepth 1 -mindepth 1 -type d | while read STUDENT_DIR; do
        echo "----------------"

        STUDENT=$(echo $STUDENT_DIR | sed -e "s/$SOLUTIONS_DIR\/[0-9]*_//" | sed -e "s/_/ /")
        echo "Student: $STUDENT ($STUDENT_DIR)"

        find "$STUDENT_DIR/" -name "${SOLUTION_NUM}_*" -maxdepth 1 -mindepth 1 -type d | while read STUDENT_SOLUTION_DIR; do
            echo "  * Solution dir: $STUDENT_SOLUTION_DIR"
            STUDENT_SOLUTION_FILE=$(ls -1 $STUDENT_SOLUTION_DIR/ | head -1)
            echo "  * Solution file: $STUDENT_SOLUTION_FILE"

            echo
            ( 
                if [[ ! $SKIP_COMPILATION && ! -e "$STUDENT_SOLUTION_FILE" ]]; then
                    echo "Compilation...."
                    cd "$STUDENT_SOLUTION_DIR"
                    $CS_COMPILER $CS_COMPILER_OPTS "$STUDENT_SOLUTION_FILE"
                fi
            ) 
            
            doTests "$STUDENT" "$STUDENT_SOLUTION_DIR/${STUDENT_SOLUTION_FILE/%.cs/.exe}"

        done
    done
}

function doTests() {
    STUDENT=$1
    SOLUTION_EXE=$2
    STUDENT_RESULTS_DIR="$RESULTS_DIR/${STUDENT// /_}"
    STUDENT_RESULTS_FILE="${STUDENT_RESULTS_DIR}/results.txt"

    echo "Testing binary: $SOLUTION_EXE"
    [ ! -d "$STUDENT_RESULTS_DIR" ] && mkdir "$STUDENT_RESULTS_DIR"


    cat $TESTS_DESC_FILE | while read TEST_NUM TEST_IN_FILE TEST_OUT_FILE TEST_MAX_TIME TEST_PARAMS; do 
        TEST_RESULT_FILE="$STUDENT_RESULTS_DIR/test${TEST_NUM}.out"
        TEST_DIFF_FILE="$STUDENT_RESULTS_DIR/test${TEST_NUM}.diff"

        echo
        echo "   * test number: $TEST_NUM"
        echo "   * test file: $TEST_IN_FILE"
        echo "   * cmd line: $MONO_CMD $SOLUTION_EXE $TEST_PARAMS < $TESTS_DIR/$TEST_IN_FILE > $TEST_RESULT_FILE "

        # handle Ctrl+C
        trap "echo; echo \"TEST INTERRUPTED!\"" SIGINT
        START_TIME=$(timer)
        $MONO_CMD $SOLUTION_EXE $TEST_PARAMS < "$TESTS_DIR/$TEST_IN_FILE" > "$TEST_RESULT_FILE"
        RESULT_TIME=$(timer $START_TIME)
        # enable handling Ctrl+C
        trap - SIGINT
        
        echo "   * test exec time: $RESULT_TIME"

        $DIFF_CMD $DIFF_OPTS "${TESTS_DIR}/${TEST_OUT_FILE}" "${TEST_RESULT_FILE}" > "${TEST_DIFF_FILE}"
        
        if [ $? -le 0 ]; then        
            if [[ $TEST_MAX_TIME -gt 0 && $RESULT_TIME -gt $TEST_MAX_TIME ]]; then 
                result="FAILED"
            else
                result="OK"
            fi
        else
            result="FAILED"
        fi

        echo "$TEST_NUM:$TEST_IN_FILE:$TEST_OUT_FILE:$result:$RESULT_TIME" >> $STUDENT_RESULTS_FILE
        echo "   * test result: $result"
    done

    # generate global report
    echo "Student: $STUDENT" >> "$RESULTS_FILE"
    echo "Results: " >> "$RESULTS_FILE"
    cat "$STUDENT_RESULTS_FILE" >> "$RESULTS_FILE"
    echo "---------------------------------------" >> "$RESULTS_FILE"

}

function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date +%s)
    else
        local  stime=$1
        etime=$(date +%s)

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        echo $dt
    fi
}

function helpme() {
    echo "Usage: "
    echo -e "\t$0 <zipfile>"
    echo "Where:"
    echo -e "\tzipfile - ZIP file with students' solutions downloaded from Codex\n"
}

SUBMITS_ZIPFILE="$1"

if [ ! -e "$SUBMITS_ZIPFILE" ];  then
    helpme
    exit 1
fi

prepareInfrastructure

prepareSolutions $SUBMITS_ZIPFILE

testSolutions $SOLUTION_NUMBER

echo
echo "Results:"
echo 
cat "$RESULTS_FILE"

