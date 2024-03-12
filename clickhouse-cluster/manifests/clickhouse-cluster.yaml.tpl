apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseInstallation"
metadata:
  name: "${name}"
  namespace: "${namespace}"
  labels:
    application_group: "${application_group }"
spec:
  configuration:
    users:
      ${user}/password: ${password}
      # to allow access outside from kubernetes
      ${user}/networks/ip: 0.0.0.0/0
      ${user}/access_management: 1
    zookeeper:
        nodes:
        - host: zookeeper.${namespace}
          port: 2181
    clusters:
      - name: "${name}"
        layout:
          shards:
            - replicas:
%{ for zone in zones ~}
                - templates:
                    podTemplate: replica-in-zone-${zone}
%{ endfor ~}
        templates:
          podTemplate: replica
          volumeClaimTemplate: data-volume-template
          serviceTemplate: internal-service-template
  templates:
    serviceTemplates:
      - name: internal-service-template
        spec:
          type: ClusterIP
          ports:
            - name: http
              port: 8123
              targetPort: 8123
            - name: tcp
              port: 9000
              targetPort: 9000
    podTemplates:
%{ for zone in zones ~}
      - name: replica-in-zone-${zone}
        zone:
          values:
            - ${zone}
        podDistribution:
          - type: ClickHouseAntiAffinity
            scope: ClickHouseInstallation
        spec:
          containers:
          - name: clickhouse
            image: altinity/clickhouse-server:23.8.8.21.altinitystable
          nodeSelector:
            node.kubernetes.io/instance-type: ${instance_type}
%{ endfor ~}
    volumeClaimTemplates:
      - name: data-volume-template
        metadata:
          labels:
            application_group: "${application_group}"
        spec:
          storageClassName: gp3-encrypted
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
