#!/bin/bash

# Testing tool for C# homework

#
# parameters
#
HOMEWORKS_TAR=$1

#
# basic settings
# 
THIS_SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd; )

# test inputs
TEST_INPUTS_DIR=${THIS_SCRIPT_DIR}/tests
# output of tests
TEST_OUTPUT_DIR=${THIS_SCRIPT_DIR}/outputs
# temporary directory to unpack tar with homeworks
TMP_DIR=${THIS_SCRIPT_DIR}/tmp

# pattern of file with source code
SOURCE_FILE_PATTERN="DU1"
SOURCE_FILE="DU1.cs"
BINARY_FILE="DU1.exe"

# if renaming of source files is required 
# - renaming finds all source files matching SOURCE_FILE_PATTERN and append .cs suffix
RENAMING_REQUIRED=true

# logfile
RESULT_LOGFILE="result.log"
NOW=$(date +%s)
GLOBAL_RESULT_LOGFILE="${TEST_OUTPUT_DIR}/allresults_${NOW}.log"

# MSC compiler
VS_HOME="/cygdrive/c/Program Files/Microsoft Visual Studio 9.0"
VC_HOME="${VS_HOME}/VC"
MSC_COMPILER_PATH="/cygdrive/c/WINDOWS/Microsoft.NET/Framework/v3.5/"
MSC_COMPILER="csc"

function init() {
        [ ! -d "${TMP_DIR}" ] && mkdir "${TMP_DIR}"
        [ ! -d "${TEST_OUTPUT_DIR}" ] && mkdir "${TEST_OUTPUT_DIR}"
        
        # setup VC variables
        
        #"${VS_HOME}/Common7/Tools/vsvars32.bat"
        
        #export PATH=${MSC_COMPILER_PATH}:/usr/bin:/bin:$PATH
}

function helpme() {
        echo "${0} - automatic tester of C# homeworks"
        echo "Usage: ${0} <tar file>"
        echo
}

function untarHomeworkTar() {
        local TAR_FILE="$1"
        echo "* Untaring input file to ${TMP_DIR} ..."
        tar -xvf "${TAR_FILE}" -C "${TMP_DIR}/"
        
        if [ -n "${RENAMING_REQUIRED}"   -a "${RENAMING_REQUIRED}" = "true"  ]; then
                echo "* renaming files matching pattern ${SOURCE_FILE_PATTERN}"
                find "${TMP_DIR}" -name "$SOURCE_FILE_PATTERN" | while read S_FILE; do                	
                	S_DIR="$(dirname "${S_FILE}")"
                	# cat "${S_FILE}" | sed -e "/using System.Linq/d" > "${S_DIR}/${SOURCE_FILE}" 
                	cat "${S_FILE}" | sed -e "s/new FileStream(\([^,]*\),[^\)]*)/new FileStream(\1,FileMode.Open, FileAccess.Read, FileShare.Read, 4096, FileOptions.SequentialScan)/g" > "${S_DIR}/${SOURCE_FILE}" 
                done
        fi
}

function getStudentName() {
        local SNAME="$1"
        SNAME=${SNAME%_*}
        echo "${SNAME}"
}

function compileSolution() {
	local SOLUTION_FILE="$1"	
	local OUTPUT_DIR="$2"
	echo "    * compiling solution ${SOLUTION_FILE} into ${OUTPUT_DIR}"
	
	cd "$(dirname "${SOLUTION_FILE}")"	
	#${MSC_COMPILER} /noconfig /nowarn:1701,1702 /errorreport:prompt /warn:4 '/define:DEBUG;TRACE' /reference:'C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.5\System.Core.dll' /reference:'C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.5\System.Data.DataSetExtensions.dll' /reference:'C:\Windows\Microsoft.NET\Framework\v2.0.50727\System.Data.dll' /reference:'C:\Windows\Microsoft.NET\Framework\v2.0.50727\System.dll' /reference:'C:\Windows\Microsoft.NET\Framework\v2.0.50727\System.Xml.dll' /reference:'C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.5\System.Xml.Linq.dll' /debug+ /debug:full /filealign:512 /optimize- "$SOURCE_FILE"
        gmcs -r:System.Data.dll,System.Core.dll "${SOURCE_FILE}" 
	cp "$(dirname "${SOLUTION_FILE}")/$BINARY_FILE" "${OUTPUT_DIR}"
	
	#echo "$(dirname "${SOLUTION_FILE}")/$BINARY_FILE"
}

function testSolution() {
        local SOLUTION_DIR="$1"        
        local OUTPUT_DIR=$(basename "${SOLUTION_DIR}")
        local OUTPUT_DIR=${TEST_OUTPUT_DIR}/${OUTPUT_DIR%_*}
        [ ! -d "${OUTPUT_DIR}" ] && mkdir "${OUTPUT_DIR}"
        local LOG_FILE="$SOLUTION_DIR/$RESULT_LOGFILE"
                
        # compile the solution
        compileSolution "${SOLUTION_DIR}/${SOURCE_FILE}" "${OUTPUT_DIR}"
        local SOLUTION_EXEC="${OUTPUT_DIR}/$BINARY_FILE"
        
        if [ ! -f "${SOLUTION_EXEC}" ]; then
        	echo "  * Compilation failed! Binary file ${SOLUTION_EXEC} does not exist!" | tee -a "${GLOBAL_RESULT_LOGFILE}"
			return                
        fi         

        find  "${TEST_INPUTS_DIR}" -name "*.txt" | while read CIRCUIT_DEF_FILE; do
                CIRCUIT_DEF_FILENAME=$(basename "$CIRCUIT_DEF_FILE")
                CIRCUIT_DEF_DIR=$(dirname "$CIRCUIT_DEF_FILE")
                echo -e "\n  ------------------" | tee -a "${GLOBAL_RESULT_LOGFILE}"                
                echo -e "\n  * testing circuit:     $CIRCUIT_DEF_FILENAME in directory $CIRCUIT_DEF_DIR" | tee -a "${GLOBAL_RESULT_LOGFILE}"
                
                find "$CIRCUIT_DEF_DIR" -name "*.in" | while read TEST_IN_FILE; do
                        
                        # original output of test
                        TEST_OUT_FILE=${TEST_IN_FILE%.in}.out
                        CIRCUIT_DEF_DIRNAME=$(basename "$CIRCUIT_DEF_DIR")
                        
                        # directory to save outputs of the solution
                        SOLUTION_TEST_OUT_DIR="$OUTPUT_DIR/$CIRCUIT_DEF_DIRNAME"
                        [ ! -d "$SOLUTION_TEST_OUT_DIR" ] && mkdir "$SOLUTION_TEST_OUT_DIR"
                        SOLUTION_OUT_FILE="$SOLUTION_TEST_OUT_DIR/$(basename "$TEST_OUT_FILE")"

                        echo -e "\n    --> testing input $TEST_IN_FILE" | tee -a "${GLOBAL_RESULT_LOGFILE}"
                        
                        if [ ! -f "$TEST_OUT_FILE" ]; then
                                echo "     - test output $TEST_OUT_FILE does not exist - TEST SKIPPED"
                                continue
                        fi
					
						# Win hack
						cd "$(dirname "${CIRCUIT_DEF_FILE}")" 																		 
						echo "cat "${TEST_IN_FILE}" | "${SOLUTION_EXEC}" "$(basename "${CIRCUIT_DEF_FILE}")"  > "${SOLUTION_OUT_FILE}""
                        cat "${TEST_IN_FILE}" | mono "${SOLUTION_EXEC}" "$(basename "${CIRCUIT_DEF_FILE}")"  > "${SOLUTION_OUT_FILE}" 
                        # 2>&1

                        # diff settings
                        # -w : ignore all white spaces
                        # -B : ignore blank lines
                        # -y : output in two columns
                        diff -w "${SOLUTION_OUT_FILE}" "${TEST_OUT_FILE}" > "${SOLUTION_OUT_FILE}_diff" 2>&1
                        
                        if [ -z "$(cat "${SOLUTION_OUT_FILE}_diff")" ]; then
                         echo "   --> test passed OK" | tee -a "${GLOBAL_RESULT_LOGFILE}"                          
                        else
                         echo "   --> test FAILED" | tee -a "${GLOBAL_RESULT_LOGFILE}"                         
                        fi
                done
        done
}

if [ -z "$1" ]; then
        helpme
        exit 1
fi

# main script

init 

untarHomeworkTar ${HOMEWORKS_TAR}

find  "${TMP_DIR}/" -mindepth 1 -type d | while read HOMEWORK_DIR; do
 STUDENT_NAME="$(getStudentName $(basename "$HOMEWORK_DIR"))"
 echo -e "\n=================================================================" | tee -a "${GLOBAL_RESULT_LOGFILE}"
 echo " * testing homework: $HOMEWORK_DIR" | tee -a "${GLOBAL_RESULT_LOGFILE}"
 echo " * student         : $(getStudentName $(basename "$HOMEWORK_DIR"))" | tee -a "${GLOBAL_RESULT_LOGFILE}"
 
 # test solution
 testSolution "$HOMEWORK_DIR" > "${TEST_OUTPUT_DIR}/${STUDENT_NAME}.log" 2>&1
 
#echo " * test passed: $TEST_PASSED" | tee -a "${GLOBAL_RESULT_LOGFILE}"
#echo " * test failed: $TEST_FAILED" | tee -a "${GLOBAL_RESULT_LOGFILE}" 
 echo -e "\n=================================================================" | tee -a "${GLOBAL_RESULT_LOGFILE}"
done

# vi: 
