#!/bin/bash

BUCKET="to-delete-soon"
FILE="covtype.data"

files=( 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n' 'o' 'p' 'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z' )

CORES=4

function timer() {
    now=$(date +"%s")
    echo "Finished in $(expr $now - $start) seconds."
}

start=$(date +"%s")
children=( )
for i in $(seq 1 $CORES); do
FILE=${files[$i-1]}
#FILE='covtype_covtype_123'
#FILE='a'
KEY="s3://$BUCKET/$FILE"
KEY='s3://h2o-datasets/covtype.data'
(echo "$i: Getting $KEY"; s3cmd --force --no-progress get "$KEY";timer ) &
children[${#children[*]}]=$!
done

cnt=${#children[@]}
for (( i=0; i < cnt; i++ )) do
    echo "Waiting for ${children[$i]} ..."
    wait ${children[$i]}
done

end=$(date +"%s")

pt=$(expr $end - $start)
echo "Time for loading $CORES x $FILE is $pt seconds" 
awk "BEGIN { print $CORES*75/$pt }"
