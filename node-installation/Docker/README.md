### Deploying GGXChain Node In Docker Container

_It is **NOT** Recommended to run GGXChain in docker for production. Suggested method is **for development and testing only** !_

**Requirements:**
* Debian base OS with Docker && Git
* Dedicated user: `sudo adduser --disabled-login --disabled-password <user_name>`
* User need to be in a docker group `usermod -aG docker <user_name>`
* In the `deploy.sh` script, changing "MY_NODE_NAME" variable is mandatory
* Please ensure that the values for `--bootnodes` and `--telemetry-url` are up to date and accurate

**_This script does not require any input, just change_ `$NODE_NAME`**

### Installation

* Prepare docker image

```sh
# Set required version
GGX_NODE_VERSION='v0.1.1'
```

```sh
# Clone & fetch, checkout
cd ~ && git clone https://github.com/ggxchain/ggxnode.git && cd ggxnode && git fetch --all --tags && git pull
git checkout ${GGX_NODE_VERSION}
```

```sh
# Build image ( this can take forever )
docker build -f Dockerfile.sydney -t ggxnode .
```

* Modify required parameters _( check script for more information )_
* Make script executable
* Run

```sh
# Make executable
chmod +x deploy.sh
```

```sh
# Execute
./deploy.sh
```

This should output container log, confirm everything works as expected, `Ctrl+C` to quit.

#### _For development and testing:_

Script can accept numbers to form nodes and containers names on the fly, such as `$MY_NODE_NAME_1`, `$MY_NODE_NAME_2`, and so on 3, 4, 5, 6 ...
* Examples:

```sh
# This will deploy MY_NODE_NAME
./deploy.sh
```

```sh
# This will deploy MY_NODE_NAME_1
./deploy.sh 1
```

```sh
# This will deploy MY_NODE_NAME_7
./deploy.sh 7
```

#### Upgrade

- checkout required version
- rebuild image
- run the script again targeting specific node

* Example: 
 
```sh
 # this will upgrade MY_NODE_NAME
./deploy.sh
```

```sh
# will upgrade MY_NODE_NAME_5
./deploy.sh 5
```

**Single MY_NODE_NAME ports are GGXChain default, except consensus p2p port can be set in script configuration**

* Example for MY_NODE_NAME

```
 Node name:       MY_NODE_NAME
 WS Port:         9944
 HTTP Rpc Port:   9933
 Prometheus Port: 9615
 P2P Port:        <AS SPECIFIED IN SCRIPT HEADER>
```

**In case of multiple nodes, all ports follow provided ${NODE_SUFFIX}, please make sure these ports are available**

* Example for MY_NODE_NAME_1

```
 Node name:       MY_NODE_NAME_1
 WS Port:         1001
 HTTP Rpc Port:   2001
 Prometheus Port: 3001
 P2P Port:        4001
```

* Example for MY_NODE_NAME_5

```
 Node name:       MY_NODE_NAME_5
 WS Port:         1005
 HTTP Rpc Port:   2005
 Prometheus Port: 3005
 P2P Port:        4005
```