# GGX Chain Grafana Dashboard

This dashboard has a complete implementation of node metrics. It can be adopted for Substrate-based systems with very little modification, such as changing the metrics prefix.

* _Grafana version: v10.0.3_

#### How to use

```sh
wget https://raw.githubusercontent.com/matsuro-hadouken/ggxchain-draft/main/grafana_custom_dashboard/ggxchain-grafana-dashboard.json
```

* In Grafana: `Dashboards => New => Import`

* Upload: `ggxchain-grafana-dashboard.json`

* Adjust datasource, instance, job if required

#### Prometheus

* **Datasource** regex is set to `/prom*/im`, this will be valid for every string contain _prom_ or _Prom_ anywhere in line. Adjust datasource variable if regex doesn't apply.
* **Job** and **Instance** will be filtered as `/.*ggx_node.*/`, please ensure correct naming or adjust filters manualy.

Example of Prometheus configuration:

```yaml
  - job_name: 'an_ggx_node_job_name'
    static_configs:
    - targets: ['100.8.97.256:999']
      labels:
        alias: 'GGX Sydney Validator SG'
        instance: equinix_ggx_node_sg_kubernetes
```

**WARNING:** Always encrypt Prometheus traffic !

#### Alerts

* Alerts present as examples in the bottom of the dashboard. Alerts doesn't supper variables, each target need to be configured manualy `job="exact_target"`

## What to expect ?

![Screenshot](https://raw.githubusercontent.com/matsuro-hadouken/ggxchain-draft/main/grafana_custom_dashboard/full-dashboard-image.png?raw=true)