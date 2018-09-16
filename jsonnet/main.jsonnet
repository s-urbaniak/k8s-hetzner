local tfvars = import 'terraform.tfvars.jsonnet';
local prom = import 'prometheus.jsonnet';
local users = import 'users.jsonnet';
local telemeter = import 'telemeter.jsonnet';
local oauthProxy = import 'oauth-proxy.jsonnet';

{ ['manifests/03-namespace-' + name ]: prom.kubePrometheus[name] for name in std.objectFields(prom.kubePrometheus) } +
{ ['manifests/04-prometheus-operator-' + name ]: prom.prometheusOperator[name] for name in std.objectFields(prom.prometheusOperator) } +
{ ['manifests/node-exporter-' + name ]: prom.nodeExporter[name] for name in std.objectFields(prom.nodeExporter) } +
{ ['manifests/kube-state-metrics-' + name ]: prom.kubeStateMetrics[name] for name in std.objectFields(prom.kubeStateMetrics) } +
{ ['manifests/alertmanager-' + name ]: prom.alertmanager[name] for name in std.objectFields(prom.alertmanager) } +
{ ['manifests/prometheus-' + name ]: prom.prometheus[name] for name in std.objectFields(prom.prometheus) } +
{ ['manifests/grafana-' + name ]: prom.grafana[name] for name in std.objectFields(prom.grafana) } +
{ ['manifests/ingress-' + name ]: prom.ingress[name] for name in std.objectFields(prom.ingress) }
{ ['manifests/user-' + name ]: users[name] for name in std.objectFields(users) } +
{ ['manifests/telemeter']: telemeter } +
{ ['manifests/oauth-proxy-' + name ]: oauthProxy[name] for name in std.objectFields(oauthProxy) } +
{ 'terraform.tfvars': tfvars }
