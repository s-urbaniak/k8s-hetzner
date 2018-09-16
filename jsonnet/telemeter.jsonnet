local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local ingress = k.extensions.v1beta1.ingress;
local ingressRule = ingress.mixin.spec.rulesType;
local httpIngressPath = ingressRule.mixin.http.pathsType;

local tfvars = import 'terraform.tfvars.jsonnet';

ingress.new() +
ingress.mixin.metadata.withName('telemeter-authorization') +
ingress.mixin.metadata.withNamespace('default') +
ingress.mixin.metadata.withAnnotations({
  'nginx.ingress.kubernetes.io/rewrite-target': '/',
  'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
}) +
ingress.mixin.spec.withRules(
  ingressRule.new() +
  ingressRule.withHost(tfvars.dns_zone) +
  ingressRule.mixin.http.withPaths(
    httpIngressPath.new() +
    httpIngressPath.withPath('/telemeter-authorization') +
    httpIngressPath.mixin.backend.withServiceName('telemeter-authorization') +
    httpIngressPath.mixin.backend.withServicePort('http')
  ),
)
