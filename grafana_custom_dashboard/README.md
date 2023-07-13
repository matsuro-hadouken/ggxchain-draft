# Base full range Grafana board for Substrate node

_Following recent research agenda, I got nothing digging for decent full-range debugging Grafana dashboard on Substrate, thought it will be worth to make one. Currently a little messy, will add more flexability on spare time to support multiple instances._

* Grafana version: 9.2.0

## Installation

Download dashboard using wget or any preferable method.

```sh
wget https://raw.githubusercontent.com/matsuro-hadouken/substrate-tools/main/substrate-custom-debug.json
```

In Grafana:

`Dashboards => New => Import`

Select: `substrate-custom-debug.json`

Adjust variables if required

## What to expect ?

![Screenshot](https://raw.githubusercontent.com/matsuro-hadouken/substrate-tools/main/grafana_custom_dashboard/substrate-custom-debug.png?raw=true)

### To do list

* ~~_Add multiple instances selector for Prometheus job_~~
* _Clean up_
