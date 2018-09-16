local k = import 'ksonnet/ksonnet.beta.3/k.libsonnet';
local rbac = k.rbac.v1beta1;
local configmap = k.core.v1.configMap;
local policyRule = rbac.clusterRole.rulesType;
local subject = rbac.clusterRoleBinding.subjectsType;
local roleRef = rbac.clusterRoleBinding.mixin.roleRef;

local admins = [
  'sergiusz.urbaniak@gmail.com',
  'stefan.schimanski@gmail.com',
  'stefanjunker86@gmail.com',
  'lserven@gmail.com',
];

{
  'role_user-admin': rbac.clusterRole.new() +
                     rbac.clusterRole.mixin.metadata.withName('user-admin') +
                     rbac.clusterRole.withRules(
                       policyRule.new() +
                       policyRule.withApiGroups(['*']) +
                       policyRule.withResources(['*']) +
                       policyRule.withVerbs(['*'])
                     ),

  'rolebinding_user-admin': rbac.clusterRoleBinding.new() +
                            rbac.clusterRoleBinding.mixin.metadata.withName('rolebinding_user-admin') +
                            rbac.clusterRoleBinding.withSubjects(
                              [
                                subject.new() +
                                subject.withName(name) +
                                subject.withApiGroup('rbac.authorization.k8s.io') +
                                { kind: 'User' }
                                for name in admins
                              ]
                            ) +
                            roleRef.withName('user-admin') +
                            roleRef.withApiGroup('rbac.authorization.k8s.io') +
                            roleRef.mixinInstance({ kind: 'ClusterRole' }),

  'oauth-users': configmap.new('oauth-users', {
                   whitelist: std.escapeStringDollars(std.lines([name for name in admins]))
                 }) +
                 configmap.mixin.metadata.withNamespace('kube-system'),
}
