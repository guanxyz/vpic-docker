#/bin/bash

# Update VPIC
cd /mnt/vpicrun/vpic
git pull

# Build VPIC
cd /mnt/vpicrun/vpic.bin
cmake \
  -DUSE_CATALYST=ON \
  -DCMAKE_BUILD_TYPE=Release \
  /mnt/vpicrun/vpic
make -j16

# PUT RUNS BELOW

# Run 1
#cd /mnt/vpicrun/vpic.bin
#export CPLUS_INCLUDE_PATH=/mnt/vpicrun/vpic/src/util/catalyst/
#mkdir -p /mnt/vpicrun/run1
#cd /mnt/vpicrun/run1
#../vpic.bin/bin/vpic ../vpic/sample/8preconnection.cxx
#cp ../vpic/sample/contourbenchmark.py ./insitu.py
#export LD_LIBRARY_PATH=/usr/local/paraview.bin/lib
#echo "Sleeping 5 to wait for filehandle."
#sleep 5
#echo "Launching 8preconnection"
#LD_LIBRARY_PATH=/usr/local/paraview.bin/lib mpiexec -machinefile /mnt/vpicrun/machinefile /mnt/vpicrun/run1/8preconnection.Linux

# Run 2
cd /mnt/vpicrun/vpic.bin
export CPLUS_INCLUDE_PATH=/mnt/vpicrun/vpic/src/util/catalyst/
mkdir -p /mnt/vpicrun/run2
cd /mnt/vpicrun/run2
../vpic.bin/bin/vpic ../vpic/sample/turbulence_master.cxx
cp ../vpic/sample/threshold.py ./insitu.py
cp ../vpic/sample/benchmark.py .
cp ../vpic/sample/parse_timings.py .
export LD_LIBRARY_PATH=/usr/local/paraview.bin/lib
echo "Sleeping 5 to wait for filehandle."
sleep 5
echo "Launching 8preconnection"
LD_LIBRARY_PATH=/usr/local/paraview.bin/lib mpiexec -machinefile /mnt/vpicrun/machinefile /mnt/vpicrun/run2/turbulence_master.Linux
