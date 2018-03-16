#!/bin/bash

# merge_csv.sh <file_1> <file_2>

FIRST=$1
SECOND=$2
#TODO: compute a proper name
OUTFILE="X.csv"

cp $FIRST $OUTFILE
tail -n +2 $SECOND >> $OUTFILE
