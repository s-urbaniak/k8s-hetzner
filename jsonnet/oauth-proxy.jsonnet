local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local tfvars = import 'terraform.tfvars.jsonnet';

local service = k.core.v1.service;
local servicePort = service.mixin.spec.portsType;

local deployment = k.apps.v1beta1.deployment;
local volume = deployment.mixin.spec.template.spec.volumesType;
local container = deployment.mixin.spec.template.spec.containersType;
local env = container.envType;
local port = container.portsType;
local volumeMount = container.volumeMountsType;

local ingress = k.extensions.v1beta1.ingress;
local ingressRule = ingress.mixin.spec.rulesType;
local httpIngressPath = ingressRule.mixin.http.pathsType;
local tls = ingress.mixin.spec.tlsType;

{
  deployment: deployment.new(
                name='oauth2-proxy',
                replicas=1,
                podLabels={
                  'k8s-app': 'oauth2-proxy',
                },
                containers=[
                  container.new(
                    name='oauth2-proxy',
                    image='docker.io/surbaniak/oauth2_proxy:b5e5d01',
                  ) +
                  container.withArgs([
                    '-provider=google',
                    '-upstream=file:///dev/null',
                    '-http-address=0.0.0.0:4180',
                    '-pass-access-token=true',
                    '-ssl-insecure-skip-verify',
                    '-authenticated-emails-file=/etc/oauth/whitelist',
                  ]) +
                  container.withEnv([
                    env.new('OAUTH2_PROXY_CLIENT_ID', tfvars.oidc_client_id),
                    env.new('OAUTH2_PROXY_CLIENT_SECRET', tfvars.oidc_client_secret),
                    env.new('OAUTH2_PROXY_COOKIE_SECRET', tfvars.oidc_cookie_secret),
                  ]) +
                  container.withPorts(
                    port.new(4180) + port.withProtocol('TCP'),
                  ) +
                  container.withVolumeMounts(
                    volumeMount.new(name='users', mountPath='/etc/oauth', readOnly=true)
                  ),
                ],
              ) +
              deployment.mixin.metadata.withNamespace('kube-system') +
              deployment.mixin.spec.selector.withMatchLabels({ 'k8s-app': 'oauth2-proxy' }) +
              deployment.mixin.spec.template.spec.withVolumes(
                volume.withName('users') +
                volume.mixin.configMap.withName('oauth-users')
              ),

  service: service.new(
             name='oauth2-proxy',
             selector={ 'k8s-app': 'oauth2-proxy' },
             ports=servicePort.newNamed(name='http', port=4180, targetPort=4180) +
                   servicePort.withProtocol('TCP'),
           ) +
           service.mixin.metadata.withLabels({ 'k8s-app': 'oauth2-proxy' }) +
           service.mixin.metadata.withNamespace('kube-system'),

  ingress: ingress.new() +
           ingress.mixin.metadata.withNamespace('kube-system') +
           ingress.mixin.metadata.withName('oauth2-proxy') +
           ingress.mixin.spec.withRules(
             ingressRule.new() +
             ingressRule.withHost(tfvars.dns_zone) +
             ingressRule.mixin.http.withPaths(
               httpIngressPath.new() +
               httpIngressPath.withPath('/oauth2') +
               httpIngressPath.mixin.backend.withServiceName('oauth2-proxy') +
               httpIngressPath.mixin.backend.withServicePort(4180)
             ),
           ) +
           ingress.mixin.spec.withTls(
             tls.new() +
             tls.withHosts([
               tfvars.dns_zone,
             ]) +
             tls.withSecretName('ingress')
           ),
}
