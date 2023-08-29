## GGX Chain Systemd Installation Guide

If you are viewing this from the console, here is the permanent link for better readability and convenience.
https://github.com/matsuro-hadouken/golden-gate-stash/tree/main/node-installation/Systemd
Repository: https://github.com/ggxchain/ggxnode

* _We're currently on the Sydney testnet. To ensure efficient debugging and testing, kindly adhere closely to the provided instructions. Please avoid reusing existing $USER and create new one exclusively. Your cooperation in this matter is greatly appreciated._

### Introduction:

In this tutorial, we will guide you through the installation of the GGX node using Systemd. However, please note that the security of your infrastructure is not addressed here. It is important to follow best practices for ensuring the security of your system. [Debian Security](https://www.debian.org/doc/manuals/securing-debian-manual/index.en.html).

The primary objective of this setup is to establish a high-performance validator. As such, it is crucial to ensure that all system resources are exclusively dedicated to our application. Deploying the application within a Docker environment is generally not recommended as each virtualization layer introduces overhead and can diminish validator performance. For optimal performance, we highly recommend running only one validator per dedicated hardware instance.

#### A little guidance for choosing hardware:
* _Reasonable Modern Linux distro ( Debian, Ubuntu )_
* _AMD Zen3 or above, Intel Ice Lake, or newer (Xeon or Core series)_
* _4 physical cores @ 3.4GHz or above_
* _Simultaneous multithreading disabled_
* _Prefer single-threaded performance over higher cores count_
* _Enterprise NVMe SSD 512GB+ ( the sizing needs to be proportionate to accommodate the growing size of the blockchain )_
* _32 GB DDR4 ECC_
* _Latest Linux Kernel_
* _A minimum symmetric networking speed of 100Mb/s is required._

### Preparation:

_Assume we logged in as our administration user who is a member of sudo group, let's go !_

```sh
# system upgrade
sudo apt update && sudo apt upgrade -y
```

* _Reboot server_

```sh
sudo apt install git wget curl jq
```

```sh
# Install requirements
sudo apt install build-essential protobuf-compiler pkg-config libssl-dev librust-clang-sys-dev -y
```

* **Create user**

This user should not be granted login privileges and should not be allowed to set any passwords.

```sh
# Create dedicated no-login user
sudo adduser --disabled-login --disabled-password ggx_user
```

```sh
# get user shell ( stay here untill we ready to start node )
sudo su - ggx_user
```

* **Set versions** _( Before integrating the parameters, kindly ensure the versions are up-to-date by performing a cross-check. )_

```sh
# Set Rust Toolchain and node binary version
# The entries below can be accidently left outdated and lead to unpredictable consequences
RUST_TOOLCHAIN='nightly-2022-12-20'
GGX_NODE_VERSION='v0.1.1'
```

* **Rust toolchain and additional components**

```sh
# Install Rust default profile
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
     --default-toolchain ${RUST_TOOLCHAIN} \
     --profile default && source "$HOME/.cargo/env"
```

```sh
# Update toolchain and set default
rustup update  ${RUST_TOOLCHAIN}
rustup default ${RUST_TOOLCHAIN}
```

```sh
# Install required components
rustup target add wasm32-unknown-unknown --toolchain ${RUST_TOOLCHAIN}
rustup component add rust-src --toolchain ${RUST_TOOLCHAIN}
```

### Installation:

```sh
# Clone repository
cd ~ && git clone https://github.com/ggxchain/ggxnode.git
cd ggxnode && git fetch --all --tags && git pull
```

```sh
# Checkout required version ( please cross-check )
git checkout ${GGX_NODE_VERSION}
```

```sh
# Build ( Sydney Testnet )
rustup run ${RUST_TOOLCHAIN} cargo build --release --package ggxchain-node --features="sydney"
```

If the build fails to succeed for any reason, please reach out to the community validators on [Dicord](https://discord.gg/ggx) for assistance.

### Server configuration

In order to ensure the provisioning of necessary resources, it is imperative to appropriately configure the system. The approach to achieving this will vary depending on the specific distribution, hardware specifications, kernel version, and other relevant factors. Attempting to provide a comprehensive and universally applicable guide in this context would be unfeasible. Therefore, we will present a concise checklist to facilitate the configuration process.

* Set CPU Governor to Performance
* Increase Max Open Files Limit to 300000+
* Make sure this adjustments is preserver on boot

### Systemd

At the time of writing this documentation, the network is in the early testnet stage. Certain variables, such as `endpoints domains`, `bootnodes`, and `telemetry`, may undergo multiple changes. To streamline the adjustment of these parameters, we will create a configuration file and include it in the systemd unit configuration. This approach enables more coherent and organized management of these parameters in a transparent and readable manner, ensuring the freshness and accuracy of the values.

**Prior to deploying the node, it is crucial to thoroughly validate all essential parameters. Here is a handy checklist to ensure a smooth deployment:**

* _Node binary version_
* _Rust toolchain version_
* _Working and active bootnode credentials_
* _Correct telemetry link_
* _Legit chainspec json file_

_Good place to confirm this is GGXChain public [Dicord](https://discord.gg/ggx) server_

#### Folders & Names

* **_Please ensure that `ggx_user` user has read and write permissions._**

```sh
# Create binary home
cd ~ && mkdir -p "${HOME}/bin"
```

```sh
# add $HOME/bin to $PATH ( bash )
echo 'export PATH="${HOME}/bin:$PATH"' >>.bashrc && . .bashrc
```

_At the time of writtining `we are on the Sydney` test network. However, can be set to your prefered location. `<NODE NAME>` is just example for better recognition, can be set according personal preference as `db`, `node_1` `data` or anything also for example._

```sh
# Create data folder aka BASE_PATH ( we will need this later, remember )
BASE_PATH="${HOME}/data-sydney/<NODE NAME>"
mkdir -p ${BASE_PATH}
```

```sh
# Path to store node key
mkdir -p ${HOME}/.node-key && chmod 0700 ${HOME}/.node-key
```

#### Make symlink to previously compiled binary

```sh
ln -s ${HOME}/ggxnode/target/release/ggxchain-node ${HOME}/bin/
```

```sh
# Test
ggxchain-node --version
```

### Creating Config

Thing to keep in mind when crafting this configuration file:

* Adjust **node name**, some special characters will not be accepted as such as `.`
* **Path should be absolute**, double check if all locations _( created above )_ are in place.
* For _author_rotateKeys_ method we do need `RPC_METHODS` to be `unsafe`, after activation please set to `safe` and **restart**
* `BASE_PATH` is where database are stored. **Point to the same location we just choose previously**
* `CUSTOM_CHAIN_SPEC` can be predefined preset, as such as `sydney` or json file with chain specification.
* Variables which can change anytime `BOOT_NODES`, `TELEMETRY_URL` _( always double check )_
* `NODE_KEY_FILE` you on your own on how to manage your `node.key`. Please follow best practices. Never stop research and improving security.
* `WS_PORT` `RPC_PORT` `PROMETHEUS_PORT` `CONSENSUS_P2P` are flexible and can be set according installation preferences.

```sh
# Create unit environment file
nano ${HOME}/bin/node.conf
```

Add the content below, make sure everything up to date

```js
RPC_METHODS=unsafe

NODE_NAME=<YOUR NODE NAME>

BASE_PATH=/home/ggx_user/data-sydney/<NODE NAME>

BOOT_NODES='/dns/sun.sydney.ggxchain.io/tcp/30333/p2p/12D3KooWGmopnFNtQb2bo1irpjPLJUnmt9K4opTSHTMhYYobB8pC'
TELEMETRY_URL='ws://18.192.225.224:8001/submit 0'

NODE_KEY_FILE=/home/ggx_user/.node-key/node.key
CUSTOM_CHAIN_SPEC=sydney

WS_PORT=9944
RPC_PORT=9933
PROMETHEUS_PORT=9615
CONSENSUS_P2P=30333

RPC_CORS=localhost

LOG_LEVEL=info

STATE_PRUNING=256
BLOCKS_PRUNING=256
```

Save configuration and exit _( this file can be easily updated later though our journey )_

```sh
# Restrict permissions
chmod 0600 ${HOME}/bin/node.conf
```

### Create Node Key

_Private keys are highly sensitive files and should be handled with utmost care. It is essential to ensure maximum protection and prevent any potential exposure. It is strongly recommended to follow best practices for keys management._ _Make sure to keep your private keys private and avoid sharing them publicly. Implement measures to safeguard the confidentiality and integrity of these keys. It is crucial to be aware of GGX Chain node key management techniques to ensure secure handling._ _Additionally, it is imperative to regularly back up your private key file and store it encrypted and securely. Losing this file can result in significant damage, so exercise caution and take appropriate measures to prevent any accidental loss._

```sh
# generate key
ggxchain-node key generate-node-key --file "${HOME}/.node-key/node.key"
```

```sh
# set permissions
chmod 0600 "${HOME}/.node-key/node.key"
```

```sh
# check public ID
ggxchain-node key inspect-node-key --file "${HOME}/.node-key/node.key"
```

_Last command will output public ID_

* _Backup this file, encrypt, save securely !_

### Create Systemd Unit Config

To continue we need sudo right
```sh
# Exit from current non-sudo user shell
exit
```

```sh
# Create systemd usnit configuration file
sudo nano /etc/systemd/system/ggx-node.service
```

Add this contend below:

```bash
[Unit]
Description=GGXChain Node
Wants=network-online.target
After=network-online.target

[Service]

User=ggx_user
Group=ggx_user

Type=simple

# Absolute path to config file created in a previous step
EnvironmentFile=/home/ggx_user/bin/node.conf

ExecStart=/home/ggx_user/bin/ggxchain-node --port ${CONSENSUS_P2P} \
        --base-path=${BASE_PATH} \
        --database rocksdb \
        --sync warp \
        --no-private-ip \
        --no-mdns \
        --state-pruning ${STATE_PRUNING} \
        --blocks-pruning ${BLOCKS_PRUNING} \
        --node-key-type ed25519 \
        --node-key-file ${NODE_KEY_FILE} \
        --log ${LOG_LEVEL} \
        --wasm-execution Compiled \
        --rpc-methods ${RPC_METHODS} \
        --rpc-cors "localhost" \
        --rpc-port ${RPC_PORT} \
        --ws-port ${WS_PORT} \
        --prometheus-port ${PROMETHEUS_PORT} \
        --name ${NODE_NAME} \
        --chain ${CUSTOM_CHAIN_SPEC} \
        --bootnodes ${BOOT_NODES} \
        --telemetry-url ${TELEMETRY_URL}

Restart=always
RestartSec=160

# We give space here for disaster prevention. Make sure system configured accordingly.
LimitNOFILE=280000

[Install]
WantedBy=multi-user.target
```

Save and exit
```sh
# Reload configuration
sudo systemctl daemon-reload
```

### Start The Node !

```sh
sudo systemctl start ggx-node.service && sudo journalctl -fu ggx-node.service -o cat
```

* _Logs should populate console screen by now, follow `monitoring` and `debugging` section of the documentation from here._

**_A little summary of what we just deployed:_**

* `WS Socket`     _bond to host on port `$WS_PORT` in a safe mod_
* `HTTP RPC`      _bond to host and exposed on port `$RPC_PORT`, set to unsafe_
* `Prometheus`    _bond to host and exposed on port `$PROMETHEUS_PORT`_
* `Consensus P2P` _bond to all interfaces and available on port `$CONSENSUS_P2P`_

**Validator**

* _This node is passive observer, validator require additional flag to be passed here `/etc/systemd/system/ggx-node.service`_

```sh
        --validator
```
* To perform the `author_rotateKeys`, execute:
```sh
curl -H "Content-Type: application/json" \
     -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
      http://localhost:$RPC_PORT
```
* After successful call, set `$RPC_METHODS` to `safe` and restart _`ggx-node.service`_

#### Node Upgrade

GGXChain offers the convenience of seamless upgrades without any downtime for validators. While detailed coverage of this feature is not within the scope of this particular discussion, you can find comprehensive information on this topic in our documentation portal.

Traditional binary upgrades require a few straightforward steps. However, before proceeding, it is essential to determine the required version for the procedure. In case the upgrade is scheduled for a specific time, it is recommended to double-check the exact timing. Once all the necessary information is confirmed, follow the simple sequence of steps outlined below:

```sh
# get user shell ( stay here untill restart is required )
sudo su - ggx_user
```
```sh
# Set version we want to apply
GGX_NODE_VERSION='<version>'
```
```sh
# pull recent changes
cd ${HOME}/ggxnode && git fetch --all --tags && git pull
```
```sh
# Checkout
git checkout ${GGX_NODE_VERSION}
```
```sh
# Build
cargo build --release --features="fast-runtime"
```

```sh
# Confirm builded version matching our expectation
ggxchain-node version
```

After restart node will switch on new version.

```sh
# Exit from current non-sudo user shell
exit
```
```sh
# Reload configuration
sudo systemctl daemon-reload
```
```sh
sudo systemctl restart ggx-node.service; sudo journalctl -fu ggx-node.service -o cat
```

**Have fun ! And if you think we can improve this documentation feel free to collaborate, [talk to us](https://discord.gg/ggx).**
