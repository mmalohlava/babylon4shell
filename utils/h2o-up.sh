#!/bin/bash

DATASET="/Users/michal/Devel/projects/h2o/repos/datasets/bench/iris/R"
DATASET="/Users/michal/Devel/projects/h2o/repos/datasets/bench/covtype/R"
DATASET="/Users/michal/Devel/projects/h2o/repos/NEW.h2o.github/smalldata/mnist"
PREFIX="mnist-"
SUFFIX=""

TRAIN="$DATASET/${PREFIX}train.csv${SUFFIX}"
TEST="$DATASET/${PREFIX}test.csv${SUFFIX}"
PORT="54321"

curl "http://localhost:$PORT/2/RemoveAll.json"
curl -F "file=@$TRAIN" "http://localhost:$PORT/2/PostFile.json?key=train.csv"
curl "http://localhost:$PORT/2/Parse2.json?source_key=train.csv&blocking"
curl -F "file=@$TEST" "http://localhost:$PORT/2/PostFile.json?key=test.csv"
curl "http://localhost:$PORT/2/Parse2.json?source_key=test.csv&blocking"

open "http://localhost:$PORT/2/DRF.query?source=train.hex&validation=test.hex"
#open "http://localhost:$PORT/2/DRF.query?source=train.hex"
#open "http://localhost:$PORT/2/GBM.query?source=train.hex"
#open "http://localhost:$PORT/2/GBM.html?source=train.hex&response=species&validation=test.hex&ntrees=274&max_depth=2&min_rows=5&nbins=20&score_each_iteration=0&learn_rate=0.2&grid_parallelism=1"
