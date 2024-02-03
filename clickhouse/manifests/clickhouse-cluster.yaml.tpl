apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseInstallation"
metadata:
  name: "${name}"
  namespace: "${namespace}"
spec:
  defaults:
    templates:
      dataVolumeClaimTemplate: data-volume-template
  configuration:
    users:
      ${user}/password: ${password}
      # to allow access outside from kubernetes
      ${user}/networks/ip: 0.0.0.0/0
  clusters:
    - name: "${name}"
      layout:
        shardsCount: 1
        replicasCount: 1
  templates:
    volumeClaimTemplates:
      - name: data-volume-template
        spec:
          storageClassName: "gp3-encrypted"
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
