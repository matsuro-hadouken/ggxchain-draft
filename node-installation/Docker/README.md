### This script theoretically deploy GoldenGate node

Is **NOT recommended** to run docker Substrate in production. We do this for development and testing porpoise only.

**Requirements:**
* Debian base OS with Docker && Git
* non-root user `adduser <user_name>`, user need to be in a docker group `usermod -aG docker <user_name>`
* edit `deploy.sh` header _( if set on new machine on dedicated user all need to be changed is node name for telemetry )_

To build image: _( this will takes forever )_, login as dedicated user,
```bash
cd $HOME && git clone https://github.com/GoldenGateGGX/golden-gate.git
```
```bash
cd golden-gate && docker build -f Dockerfile.sydney -t golden-gate-node .
```
After image successful build
```bash
chmod +x deploy.sh
```
```bash
./deploy.sh
```
This should output container log, confirm everything works as expected, `Ctrl+C` to quit. Check - `docker ps`
