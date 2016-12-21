
<h3> Running Catalyst VPIC using Docker in AWS </h3>

Follow the DSS Viz Wiki instructions on configuring and starting a cluster https://darwin.lanl.gov/projects/vizproject/wiki/AWS-setup-notes and https://darwin.lanl.gov/projects/vizproject/wiki/Starcluster-notes.

Once a Starcluster Enviroment is configured (see below), running VPIC in AWS consists of logging into a StarCluster from your local machine. 
````
starcluster start -x <clustername>
starcluster sshmaster <clustername>
````
Then pulling the VPIC code from docker and configuring your parallel environment.
````
cd /home/vpic
git clone https://github.com/Tomyao/vpicdocker.git
cd vpicdocker
mkdir -p ../vpicrun
chmod 777 -R ../vpicrun
````
Once logged into the StarCluster, you will need to edit _hostfile_ and _machinefile_ to reflect the topology of the cluster that you 
have launched.  _hostfile_ is in OpenMPI format and should have 1 slot per node and is used to launch docker on each node.
_machinefile_ should be in MPICH format and have one slot per core or virtual processor in AWS.

Examples for configuring parallelism:
````
Hostfile for a four node StarCluster:
  master slots=1
  node001 slots=1
  node002 slots=1
  node003 slots=1
  
Machinefile of 4 node cluster of m3.xlarge instances with 4 vCPUS:
  master:4
  node001:4
  node002:4
  node003:4
````
Build the docker image with:
````
mpirun -hostfile hostfile --mca btl_tcp_if_include eth0 ./mpibuild_vpic.sh --verbose
````

<h3> Interactive Launch </h3>
   
  * Test your installation with an interactive launch.  The following starts sshd on all the slave docker containers in the background, then launches a root bash shell on the master node docker container, and then runs the simulation.
````
mpirun -hostfile hostfile --mca btl_tcp_if_include eth0 ./mpirun_sshd.sh --verbose
docker run -it --net=host -v /home/vpic/vpicrun:/mnt/vpicrun vpic /bin/bash
./launch.sh
````
Running docker with the _-it_ option gives you an interactive shell inside the container that you can use to edit and run codes.

  * Monitor the output -- from the virtual machine (not inside the container).  You will need another shell.
  
````
tail -f /home/vpic/vpicrun/.....
````

  * Terminate the docker containers running the cluster.  This is run from the StarCluster shell, not inside the container.
````
mpirun -hostfile hostfile --mca btl_tcp_if_include eth0 ./mpistopcluster.sh --verbose
````

<h3> Configuring a Run </h3>
Make a config file like below:
````
# Folder Name
<folder name>
# Deck
<deck path>
# Files
<file 1 path>
<file 2 path>
# Scripts
<script 1 path>
<script 2 path>
# End
````
The folder name is the name (not path) of the folder where the run is going to occur. The deck name is the input deck path. The file paths are the files (excluding the in-situ scripts) that you want to be in the same folder as where the run is going to occur. The script paths are the paths of the in-situ scripts that you want to run. Make sure to keep # Folder Name, # Deck, # Files, # Scripts, and # End, since runvpic.sh will use them to parse for the correct information.
