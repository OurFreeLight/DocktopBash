#!/usr/bin/env bash

SOURCE=$1
DEST=$2

xsel --clipboard --output --display $SOURCE | xsel --clipboard --input --display $DEST