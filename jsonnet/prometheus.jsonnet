local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';

local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') {
  _config+:: {
    namespace: 'monitoring',
  },
};

local tfvars = import 'terraform.tfvars.jsonnet';
local secret = k.core.v1.secret;
local ingress = k.extensions.v1beta1.ingress;
local ingressTls = ingress.mixin.spec.tlsType;
local ingressRule = ingress.mixin.spec.rulesType;
local httpIngressPath = ingressRule.mixin.http.pathsType;

local newIngress(svc, svcPort) =
  ingress.new() +
  ingress.mixin.metadata.withName(svc) +
  ingress.mixin.metadata.withNamespace('monitoring') +
  ingress.mixin.metadata.withAnnotations({
    'nginx.ingress.kubernetes.io/rewrite-target': '/',
    'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',    
    'nginx.ingress.kubernetes.io/auth-url': std.format("https://%s/oauth2/auth", tfvars.dns_zone),
    'nginx.ingress.kubernetes.io/auth-signin': std.format("https://%s/oauth2/start?rd=$escaped_request_uri", tfvars.dns_zone),
  }) +
  ingress.mixin.spec.withRules(
    ingressRule.new() +
    ingressRule.withHost(tfvars.dns_zone) +
    ingressRule.mixin.http.withPaths(
      httpIngressPath.new() +
      httpIngressPath.withPath('/' + svc) +
      httpIngressPath.mixin.backend.withServiceName(svc) +
      httpIngressPath.mixin.backend.withServicePort(svcPort)
    ),
  );

local ingress = {
  grafana: newIngress('grafana', 3000),
} {
  prometheus: newIngress('prometheus-k8s', 'web'),
};

local prometheus = kp.prometheus {
  prometheus+: { spec+: {
    externalUrl: std.format('https://%s/prometheus-k8s', tfvars.dns_zone),
  } },
};

local grafana = kp.grafana {
  deployment+: { spec+: { template+: { spec+: {
    containers:
      local cs = kp.grafana.deployment.spec.template.spec.containers;
      [
        c + if c.name == 'grafana'
        then {
          env: [
            { name: 'GF_SERVER_ROOT_URL', value: std.format('https://%s/grafana', tfvars.dns_zone) },
          ],
        }
        else {}
        for c in cs
      ],
  } } } },
};

kp {
  prometheus: prometheus,
  grafana: grafana,
  ingress: ingress,
}
