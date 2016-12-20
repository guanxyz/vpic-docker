#/bin/bash

# NOTE: Configure the run using the Config file

# Pull information from Config
file="./vpic_config"
FLAG=0
file_list=()
script_list=()
while IFS= read -r line
do
    if [ "$line" == "# Folder Name" ]; then
        FLAG=1
        continue
    fi
    if [ "$line" == "# Deck" ]; then
        FLAG=2
        continue
    fi
    if [ "$line" == "# Files" ]; then
        FLAG=3
        continue
    fi
    if [ "$line" == "# Scripts" ]; then
        FLAG=4
        continue
    fi
    if [ $FLAG == 1 ]; then
        folder_name="$line"
        continue
    fi
    if [ $FLAG == 2 ]; then
        deck_name="$line"
        continue
    fi
    if [ $FLAG == 3 ]; then
        file_list+=("$line")
        continue
    fi
    if [ $FLAG == 4 ]; then
        script_list+=("$line")
    fi
done <"$file"

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

# Create Folder
mkdir -p /mnt/vpicrun/$folder_name

# Copy Files
for i in "${file_list[@]}"; do
    cp $i /mnt/vpicrun/$folder_name
done

# Copy Scripts
for i in "${script_list[@]}"; do
    cp $i /mnt/vpicrun/$folder_name
done

# Configure insitu.py and move it
rm insitu.py
touch insitu.py
for i in "${script_list[@]}"; do
    filename="${i##*/}"
    scriptname="${filename%.*}"
    printf "import $scriptname\n" >> insitu.py
done
echo "def RequestDataDescription(datadescription):\n" >> insitu.py
for i in "${script_list[@]}"; do
    filename="${i##*/}"
    scriptname="${filename%.*}"
    printf "\t$scriptname.RequestDataDescription(datadescription)\n" >> insitu.py
done
echo "def DoCoProcessing(datadescription):\n" >> insitu.py
for i in "${script_list[@]}"; do
    filename="${i##*/}"
    scriptname="${filename%.*}"
    printf "\t$scriptname.DoCoProcessing(datadescription)\n" >> insitu.py
done
mv insitu.py /mnt/vpicrun/$folder_name

# Compile deck and configure libraries
cd /mnt/vpicrun/vpic.bin
export CPLUS_INCLUDE_PATH=/mnt/vpicrun/vpic/src/util/catalyst/
cd /mnt/vpicrun/$folder_name
../vpic.bin/bin/vpic $deck_name
export LD_LIBRARY_PATH=/usr/local/paraview.bin/lib
echo "Sleeping 5 to wait for filehandle."
sleep 5
echo "Launching..."
# Get executable name
temp="${deck_name##*/}"
executable="${temp%.*}.Linux"
# Run it
LD_LIBRARY_PATH=/usr/local/paraview.bin/lib mpiexec -machinefile /mnt/vpicrun/machinefile /mnt/vpicrun/$folder_name/$executable
