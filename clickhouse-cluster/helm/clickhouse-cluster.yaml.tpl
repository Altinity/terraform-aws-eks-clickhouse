all:
  metadata:
    labels:
      application_group: ${name}

clickhouse:
  name: ${name}
  cluster: ${cluster_name}
  zones:
%{ for zone in zones ~}
    - ${zone}
%{ endfor ~}
  node_selector: "${instance_type}"
  service_type: "${service_type}"
  storage_class_name: gp3-encrypted
  password: ${password}
  user: ${user}
  keeper_name: clickhouse-keeper-sts
