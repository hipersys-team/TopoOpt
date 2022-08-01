#!/bin/bash

FF_HOME=$HOME/FlexFlow

cd $FF_HOME/ffsim_opera
git checkout clean
cd src/clos
make clean
make -j $(nproc)
cd datacenter
make clean
make -j $(nproc)