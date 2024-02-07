apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseInstallation"
metadata:
  name: "${name}"
  namespace: "${namespace}"
spec:
  configuration:
    users:
      ${user}/password: ${password}
      # to allow access outside from kubernetes
      ${user}/networks/ip: 0.0.0.0/0
    zookeeper:
        nodes:
        - host: zookeeper.${zookeeper_namespace}
          port: 2181
    clusters:
      - name: "${name}"
        layout:
          shardsCount: 1
          replicasCount: 1
        templates:
          podTemplate: clickhouse-stable
          volumeClaimTemplate: data-volume-template
  templates:
    podTemplates:
      - name: clickhouse-stable
        spec:
          containers:
          - name: clickhouse
            image: altinity/clickhouse-server:21.8.10.1.altinitystable
    volumeClaimTemplates:
      - name: data-volume-template
        spec:
          storageClassName: gp3-encrypted
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
