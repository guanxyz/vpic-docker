#/bin/bash

# Build VPIC
cd /mnt/vpicrun/vpic.bin
cmake \
  -DUSE_CATALYST=ON \
  -DCMAKE_BUILD_TYPE=Release \
  /mnt/vpicrun/vpic
make -j16

# PUT RUNS BELOW

# Run 1
cd /mnt/vpicrun/vpic.bin
export CPLUS_INCLUDE_PATH=/mnt/vpicrun/vpic/src/util/catalyst/
mkdir -p /mnt/vpicrun/run1
cd /mnt/vpicrun/run1
/mnt/vpicrun/vpic.bin/bin/vpic ../vpic/sample/8preconnection.cxx
export LD_LIBRARY_PATH=/usr/local/paraview.bin/lib
echo "Sleeping 5 to wait for filehandle."
sleep 5
echo "Launching 8preconnection"
LD_LIBRARY_PATH=/usr/local/paraview.bin/lib mpiexec -machinefile /mnt/vpicrun/machinefile /mnt/vpicrun/run1/8preconnection.Linux
