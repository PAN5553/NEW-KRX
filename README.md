# Keryx Miner KRX HiveOS Custom Miner

HiveOS custom miner package for Keryx Miner KRX.

## Miner

- Name: `keryx-miner-v0.1.4.7-OPoI`
- Version: `0.1.4.7`
- Binary: `keryx-miner`
- Algorithm: `keryxhash`
- Coin: `KRX`
- Default pool: `stratum+tcp://krx.suprnova.cc:4404`

## Files

- `h-manifest.conf` defines HiveOS custom miner metadata.
- `h-config.sh` writes `config.ini` from HiveOS flight sheet variables.
- `h-run.sh` creates config and launches `keryx-miner --config config.ini`.
- `h-stats.sh` prints HiveOS compatible JSON with hashrate, GPU temperature, fan, power, accepted shares, and rejected shares.
- `build.sh` creates `keryx-miner-v0.1.4.7-hiveos.tar.gz`.
- `package.sh` is a wrapper for `build.sh`.

## Configuration

`h-config.sh` supports a full custom config through the `CUSTOM_CONFIG_CONTENT` environment variable. If `CUSTOM_CONFIG_CONTENT` is not set, it creates `config.ini` from HiveOS values:

- Pool: `CUSTOM_URL`, `CUSTOM_POOL`, or the default pool.
- Wallet/template: `CUSTOM_TEMPLATE`, `CUSTOM_WALLET`, or `CUSTOM_USER`.
- Password: `CUSTOM_PASS`, default `x`.
- Worker: `CUSTOM_WORKER`, `WORKER_NAME`, or host name.
- Extra miner options: `CUSTOM_USER_CONFIG`.

Example generated `config.ini`:

```ini
[miner]
algorithm=keryxhash
coin=KRX
pool=stratum+tcp://krx.suprnova.cc:4404
wallet=YOUR_KRX_WALLET
password=x
worker=rig01
api_port=4068
log_file=/var/log/miner/keryx-miner.log

[advanced]
extra_args=
```

## Build

Place the Linux `keryx-miner` executable in this directory, then run:

```bash
./build.sh
```

Or build with a binary from another path:

```bash
KERYX_MINER_BINARY=/path/to/keryx-miner ./build.sh
```

The build output is:

```text
keryx-miner-v0.1.4.7-hiveos.tar.gz
```

## HiveOS Installation

Copy the archive to the HiveOS rig and install it as a custom miner:

```bash
scp keryx-miner-v0.1.4.7-hiveos.tar.gz user@rig:/tmp/
ssh user@rig
sudo mkdir -p /hive/miners/custom/keryx-miner-v0.1.4.7-OPoI
sudo tar -xzf /tmp/keryx-miner-v0.1.4.7-hiveos.tar.gz -C /hive/miners/custom/keryx-miner-v0.1.4.7-OPoI --strip-components=1
sudo chmod +x /hive/miners/custom/keryx-miner-v0.1.4.7-OPoI/h-*.sh
sudo chmod +x /hive/miners/custom/keryx-miner-v0.1.4.7-OPoI/keryx-miner
```

In HiveOS, create a custom miner flight sheet:

- Miner name: `keryx-miner-v0.1.4.7-OPoI`
- Algorithm: `keryxhash`
- Wallet/template: your KRX wallet or pool login.
- Pool URL: `stratum+tcp://krx.suprnova.cc:4404`
- Password: `x` unless your pool requires another value.

Start or restart the miner from HiveOS after applying the flight sheet.

## Stats

`h-stats.sh` attempts to read Keryx Miner API JSON from:

- `http://127.0.0.1:4068/stats`
- `http://127.0.0.1:4068/summary`

If miner API telemetry is unavailable, it returns safe defaults and uses HiveOS GPU telemetry where available. Output format:

```json
{"khs":[0],"hs":[0],"hs_total":0,"hs_units":"h/s","temp":[],"fan":[],"power":[],"ar":[0,0],"stats":{"accepted":0,"rejected":0,"hashrate_hs":0},"uptime":0,"algo":"keryxhash","coin":"KRX","ver":"0.1.4.7"}
```
