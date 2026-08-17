#!/usr/bin/env bash
# Compiles the AS3 menu shell into a single SWF using mxmlc.
# Requires mxmlc on PATH -- see README.md for where to get it.
set -e
 
mkdir -p bin
mxmlc \
  -source-path=src \
  -output=bin/VoxelPE.swf \
  -static-link-runtime-shared-libraries=true \
  src/Main.as
 
echo "Built bin/VoxelPE.swf"
 
