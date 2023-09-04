#!/bin/bash

# This script does not require any input, just change $NODE_NAME!

# For development and testing:

# Script can accept numbers to form nodes and containers names such as '$MY_NODE_NAME_1', '$MY_NODE_NAME_2', and so on 3, 4, 5, 6 ...
# Example: './deploy.sh 1'
# This will deploy 'MY_NODE_NAME_1'.
# Example: './deploy.sh 7'
# This will deploy MY_NODE_NAME_7 and so on.

# To upgrade run the script again one more time with the appropriate number or without in case of a single container:
# Example: './deploy.sh 1' will upgrade MY_NODE_NAME_1.
# Example: './deploy.sh'   this will upgrade MY_NODE_NAME.

# In case of multiple nodes, all ports are distributed as '100${NODE_SUFFIX}', please make sure these ports are available!

# SET NODE NAME HERE ==>
                                
MY_NODE_NAME="my_node_name_here" # Try to use only letters and numbers ( underscore accepted )
                                
# Double check up to date values of '$BOOT_NODE' && '$TELEMETRY' !!!
BOOT_NODE="/dns/sun.sydney.ggxchain.io/tcp/30333/p2p/12D3KooWGmopnFNtQb2bo1irpjPLJUnmt9K4opTSHTMhYYobB8pC" # Boot from here
TELEMETRY='wss://telemetry.sydney.ggxchain.io/submit 0' # Telemetry endpoint

# Consensus port in case of multiple containers will stay on '400x' where 'x' is provided integer. Example: 4001, 4002, 4003 and so on ...

# Set custom consensus port here for a single docker deployment.
P2P_PORT=12345

docker_image="ggxnode" # name of the docker image [ to build: 'docker build -f Dockerfile.sydney -t ggxnode' ]

# -------------------------------------------------------------------------------------------

NODE_SUFFIX="${1}"                          # prefix need to be integer 1 2 3 4 5 ... 'OR' none !

node_name="${MY_NODE_NAME}"_"${NODE_SUFFIX}" # construct node name ( may_node_name_1 )

# This is critial ! All nodes will be isolated accordingly
# Set the global storage folder for databases
global_storage_folder="data-sydney" 

# -------------------------------------------------------------------------------------------

# Data folder path for a particular node database
data_folder_path="${HOME}/${global_storage_folder}/${node_name}"

# Ports distributed accordingly to SUFFIX, 'please make sure' they are available !
ws_port=100"${NODE_SUFFIX}"         # default 9944
http_port=200"${NODE_SUFFIX}"       # default 9933
prometheus_port=300"${NODE_SUFFIX}" # default 9615
consensus_port=400"${NODE_SUFFIX}"  # default 30333

echo

re='^[0-9]+$'

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# If NODE_SUFFIX is empty
if [ -z "$NODE_SUFFIX" ]; then

    echo -e " Target node: ${GREEN}$MY_NODE_NAME${NC}" && echo
    node_name="${MY_NODE_NAME}" # construct node name
    data_folder_path="${HOME}/${global_storage_folder}/${node_name}" # particular node storage path

    # use default
    ws_port=9944                 # 9944
    http_port=9933               # 9933
    prometheus_port=9615         # 9615
    # Care about Frankfurt folks
    consensus_port="${P2P_PORT}" # 30333

else

    # check if provided value is integer
    if ! [[ $NODE_SUFFIX =~ $re ]]; then
        echo -e " ${RED}ERROR:${NC} Node suffix need to be integer !" && echo
        exit 1
    else
        echo -e " Target node: ${GREEN}$node_name${NC}" && echo
    fi

fi

# Create storage path, if doesn't exist
if [ ! -d "$data_folder_path" ]; then
    echo -e " Data storage path does not exist, creating: ${CYAN}${data_folder_path}${NC}" && mkdir -p "$data_folder_path"
else
    echo -e " Data storage path is set to: ${CYAN}${data_folder_path}${NC}"
fi

if [ ! -f "${data_folder_path}"/node.key ]; then
    echo && echo -e " ${RED}ERROR:${NC} node.key doesn't exist, you need to create one like this:" && echo
    echo -e " ${GREEN}docker run --rm -ti -v ${data_folder_path}:/data-sydney ${docker_image} key generate-node-key --file /data-sydney/node.key${NC}" && echo
    exit 1
fi

if ! [[ $node_name =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo -e " ${YELLOW}WARNING:${NC} Prefix set to something overcomplicated, please follow: ${CYAN}^[a-zA-Z0-9_]${NC}" && exit 1
fi

echo
echo -e " Node name:       ${GREEN}$node_name${NC}"
echo -e " WS Port:         ${GREEN}$ws_port${NC}"
echo -e " HTTP Rpc Port:   ${GREEN}$http_port${NC}"
echo -e " Prometheus Port: ${GREEN}$prometheus_port${NC}"
echo -e " P2P Port:        ${GREEN}$consensus_port${NC}" && echo

echo -e " Bootnode:        ${GREEN}${BOOT_NODE}${NC}"
echo -e " Telemetry URL:   ${GREEN}${TELEMETRY}${NC}" && echo && sleep 3

container_status=$(docker inspect -f '{{.State.Status}}' "${node_name}" 2>/dev/null)

function requirements() {

    if [[ "$container_status" == "running" ]]; then

        echo -e " ${YELLOW}WARNING:${NC} Container is running, stopping now and removing ..." && echo
        docker stop "${node_name}" && docker rm "${node_name}" && echo

    else

        if docker inspect "${node_name}" >/dev/null 2>&1; then
            echo -e " ${YELLOW}WARNING:${NC} Container exists, removing ..." && echo
        else
            echo -e " ${YELLOW}WARNING:${NC} Container does not exist !" && echo
        fi

    fi

    sleep 2

}

function deploy_container() {

    echo -e " ${GREEN}Deploying new container:${NC} ${CYAN}${node_name}${NC}" && echo

    cd "${HOME}/ggxnode" &&
        docker run -d -it --restart=unless-stopped --ulimit nofile=100000:100000 --name "${node_name}" \
            -p "127.0.0.1:$ws_port:9944" \
            -p "127.0.0.1:$http_port:9933" \
            -p "0.0.0.0:$prometheus_port:9615" \
            -p "$consensus_port:30333" \
            -v "${data_folder_path}":/data-sydney ${docker_image} \
            --validator \
            --base-path=/data-sydney \
            --rpc-cors all \
            --database rocksdb \
            --sync warp \
            --no-private-ip \
            --no-mdns \
            --state-pruning 256 \
            --blocks-pruning 256 \
            --node-key-type ed25519 \
            --node-key-file "${data_folder_path}"/node.key \
            --log info \
            --rpc-methods unsafe \
            --unsafe-rpc-external \
            --unsafe-ws-external \
            --prometheus-external \
            --name "$node_name" \
            --wasm-execution Compiled \
            --chain sydney \
            --bootnodes "${BOOT_NODE}" \
            --telemetry-url "${TELEMETRY}"

    echo

}

requirements && deploy_container && docker logs "${node_name}" --follow --tail 60

echo && echo -e ${GREEN}" Blocks ?${NC}" && echo
