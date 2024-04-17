# Default values for 1-node ClickHouse server (chi) and Keeper (chk) resources.

all:
  metadata:
    labels:
      application_group: "eks"

clickhouse:
  name: ${cluster_name}
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

keeper:
  name: keeper-${cluster_name}
  cluster: chk
  zones:
%{ for zone in zones ~}
    - ${zone}
%{ endfor ~}
  node_selector: "${instance_type}"
