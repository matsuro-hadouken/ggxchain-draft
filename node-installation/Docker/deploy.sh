#!/bin/bash

# 'Requirements:'
# Debian base OS with Docker and Git

# to build image ( this will takes forever )
# 'cd ~ && git clone https://github.com/ggxchain/ggxnode.git'
# 'cd ggxnode && git fetch --all --tags && git pull'
# 'docker build -f Dockerfile.sydney -t ggx-node .'

# 'CONFIGURATION ==>'

node_name="Node Name Here"  # mandatory, it will be visible on telemetry

container_name="ggxnode"    # container name to identify

# all ports can be customized, including consensus port ( we do not use 'ws' in this deployment sorry )
http_port=9933        # default - 9933
prometheus_port=9615  # default - 9615
consensus_port=30333  # default - 30333

# global storage folder to store data for all nodes $HOME/data-sydney
global_storage_folder="data-sydney"

# particular node data isolated here. In this example we use '$container_name' variable as final destination.
data_folder_path="${HOME}/${global_storage_folder}/${container_name}"

# Docker image ( we will build this manualy because no releases available )
# As we do not have any release tags or versions, we build master 'in hope' it will just works. However, some breaking changes can lead to disaster.
# In case of disaster - need to bruteforce current working commit relaying on recent accepted pull requests ( something like this )
DockerImageName="ggx-node"

# To proceed with the execution of the `author_rotateKeys` method, an HTTP endpoint is required. Presently, the
# HTTP endpoint is accessible through the 127.0.0.1 interface.
# However, it is important to emphasize that once the keys rotation procedure is completed,it becomes essential to protect the RPC to ensure secure communication.
# It is strongly advised to adhere to industry best practices for securing the RPC endpoint.
# While this tutorial script does not cover the specific security aspects in detail, it is expected that
# professionals and individuals familiar with engineering and DevOps practices will prioritize and implement the necessary security measures.

# Please ensure that values for `BOOTNODES` and `TELEMETRY_URL` are up to date and accurate
BOOTNODES='/ip4/3.69.173.157/tcp/30333/p2p/12D3KooWSriyuFSmvuc188UWqV6Un7YYCTcGcoSJcoyhtTZEWi1n'
TELEMETRY_URL='wss://test.telemetry.sydney.ggxchain.io/submit'

# -------------------------------------  ' END OF CONFIG ' ------------------------------------------------------

# Should not be run as root
if [[ $EUID -eq 0 ]]; then
    echo && echo "Sorry, but this script cannot be run as root" && echo
    exit 1
fi

# check if container exist and if exist stop and remove
if ! [[ $(docker ps -a -q -f name=$container_name) ]]; then
  echo && echo " Container $container_name exist, removing ..." && echo
  docker stop "${container_name}" && docker rm "${container_name}" && sleep 2 && echo
fi

echo " Deploying new container ..." && echo

mkdir -p "${data_folder_path}" # create data directory for this particular node

cd "${HOME}/ggxnode" &&
    docker run -d -it --restart=unless-stopped --ulimit nofile=100000:100000 --name "${container_name}" \
        -p "127.0.0.1:$ws_port:9944" \
        -p "127.0.0.1:$http_port:9933" \
        -p "127.0.0.1:$prometheus_port:9615" \
        -p "0.0.0.0:$consensus_port:30333" \
        -v "$HOME"/ggxnode/custom-spec-files:/tmp \
        -v "${data_folder_path}":/data-sydney "${DockerImageName}" \
        --base-path=/data-sydney \
        --rpc-cors all \
        --database rocksdb \
        --sync warp \
        --no-private-ip \
        --no-mdns \
        --state-pruning 256 \
        --blocks-pruning 256 \
        --node-key-type ed25519 \
        --node-key-file /data-sydney/node.key \
        --log info \
        --rpc-methods unsafe \
        --unsafe-rpc-external \
        --prometheus-external \
        --validator \
        --name "$node_name" \
        --wasm-execution Compiled \
        --chain /tmp/sydney.json \
        --bootnodes "${BOOTNODES}" \
        --telemetry-url "${TELEMETRY_URL} 0"

echo

docker logs "${container_name}" --follow --tail 60

echo && echo " Blocks ?" && echo
