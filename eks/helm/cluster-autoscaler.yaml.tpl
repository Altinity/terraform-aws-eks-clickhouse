autoDiscovery:
  clusterName: ${eks_cluster_id}
  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/${eks_cluster_id}

awsRegion: ${aws_region}

cloudProvider: aws

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "${role_arn}"
  create: true
  name: cluster-autoscaler

rbac:
  create: true
  # Fix for volumeattachments permission issue in K8s 1.33+
  clusterRole:
    extraRules:
    - apiGroups: ["storage.k8s.io"]
      resources: ["volumeattachments"]
      verbs: ["list", "watch", "get"]

extraArgs:
  logtostderr: true
  stderrthreshold: info
  v: 4
  balance-similar-node-groups: true
  skip-nodes-with-local-storage: false
  skip-nodes-with-system-pods: false
  expander: most-pods

image:
  tag: ${autoscaler_version}

replicaCount: ${autoscaler_replicas}

resources:
  limits:
    cpu: "100m"
    memory: "600Mi"
  requests:
    cpu: "100m"
    memory: "600Mi"

podDisruptionBudget:
  maxUnavailable: 1

priorityClassName: "system-cluster-critical"
