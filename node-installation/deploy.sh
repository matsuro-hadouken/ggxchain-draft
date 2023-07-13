#!/bin/bash

# This script theoretically deploy GoldenGate node

# Is 'NOT recommended' to run docker Substrate in production. We do this for development and testing porpoise only.

# 'Requirements:'
# Debian base OS with Docker and Git
# non-root user 'adduser <user_name>', user need to be in a docker group. 'usermod -aG docker <user_name>'

# to build image ( this will takes forever ), login as dedicated user,
# 'cd $HOME && git clone https://github.com/GoldenGateGGX/golden-gate.git'
# 'cd golden-gate && docker build -f Dockerfile.sydney -t golden-gate-node .'

# 'CONFIGURATION ==>'

node_name="Node Name Here"                 # it will be visible on telemetry

container_name="golden_gate_node_1"        # container name to identify

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
DockerImageName="golden-gate-node"

# HTTP endpoint is required for keys_rotation method execution, HTTP endpoint exposed on 127.0.0.1 interface,
# however, after keys rotation procedure, RPC should be protected. Please 'follow best security practice'.
# Security 'is not' in a scope of this tutorial script.
# To be able to proceed keys rotation we need '--rpc-methods unsafe' and '--unsafe-rpc-external' this is practically security vulnerability
# you should restart node without this flags. Prometheus exposed on 127.0.0.1, remove prometheus related flags if not required.

# -------------------------------------  ' END OF CONFIG ' ------------------------------------------------------

# Should not be run as root
if [[ $EUID -eq 0 ]]; then
    echo && echo "This script cannot be run as root." && echo
    exit 1
fi

# check if container exist and if exist stop and remove
if ! [[ $(docker ps -a -q -f name=$container_name) ]]; then
  echo && echo " Container $container_name exist, removing ..." && echo
  docker stop "${container_name}" && docker rm "${container_name}" && sleep 2 && echo
fi

echo " Deploying new container ..." && echo

mkdir -p "${data_folder_path}" # create data directory for this particular node

cd "${HOME}/golden-gate" &&
    docker run -d -it --restart=unless-stopped --ulimit nofile=100000:100000 --name "${container_name}" \
        -p "127.0.0.1:$ws_port:9944" \
        -p "127.0.0.1:$http_port:9933" \
        -p "127.0.0.1:$prometheus_port:9615" \
        -p "0.0.0.0:$consensus_port:30333" \
        -v "$HOME"/golden-gate/custom-spec-files:/tmp \
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
        --bootnodes '/ip4/3.69.173.157/tcp/30333/p2p/12D3KooWSriyuFSmvuc188UWqV6Un7YYCTcGcoSJcoyhtTZEWi1n' \
        --telemetry-url 'wss://test.telemetry.sydney.ggxchain.io/submit 0'

echo

docker logs "${container_name}" --follow --tail 60

echo && echo " Blocks ?" && echo
