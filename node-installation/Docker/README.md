### This script theoretically deploy GGXChain node

Is **NOT Recommended** to run node in docker for production. We do this for development and testing porpoise only.

**Requirements:**
* Debian base OS with Docker && Git
* User need to be in a docker group `usermod -aG docker <user_name>`
* In the `deploy.sh` script, you probably only need to update the node name for telemetry
* Please ensure that the values for `--bootnodes` and `--telemetry-url` are up to date and accurate

**Please review `deploy.sh` and modify the configuration section accordingly.**

```sh
# Set required version
GGX_NODE_VERSION='v1.0.0'
```

```sh
# Clone & fetch
cd ~ && git clone https://github.com/ggxchain/ggxnode.git && cd ggxnode && git fetch --all --tags && git pull
git checkout ${GGX_NODE_VERSION}
```

```sh
# Build image ( this can take forever )
docker build -f Dockerfile.sydney -t ggx-node .
```
After image successfully build
```sh
# Make executable
chmod +x deploy.sh
```
```sh
# Execute
./deploy.sh
```
This should output container log, confirm everything works as expected, `Ctrl+C` to quit.

* To upgrade, rebuild image, run script one more time
