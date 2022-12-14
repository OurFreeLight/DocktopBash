#!/usr/bin/env bash

set -e

TEMP_ARGS="$@"

source ./run_parse.sh

if [ "$TYPE" == "custom" ]; then
  cd ./workspaces/
  ./run.sh $TEMP_ARGS
  cd ..

  exit;
fi

if [ "$TYPE" == "all" ] || [ "$TYPE" == "base" ]; then
  cd ./images/
  ./run.sh $TEMP_ARGS
  cd ..;
fi

if [ "$TYPE" == "all" ] || [ "$TYPE" == "workspace" ] || [ "$TYPE" == "developer" ] || [ "$TYPE" == "steam" ]; then
  cd ./workspaces/
  ./run.sh $TEMP_ARGS
  cd ..;
fi