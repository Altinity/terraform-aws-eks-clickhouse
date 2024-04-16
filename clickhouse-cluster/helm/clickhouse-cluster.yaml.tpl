# Default values for 1-node ClickHouse server (chi) and Keeper (chk) resources.

all:
  metadata:
    labels:
      application_group: "aws"

clickhouse:
  name: aws
  cluster: ch
  zones:
%{ for zone in zones ~}
    - ${zone}
%{ endfor ~}
  node_selector: "${instance_type}"
  service_type: "${service_type}"
  storage: 50Gi

keeper:
  name: aws-keeper
  cluster: chk
  zones:
%{ for zone in zones ~}
    - ${zone}
%{ endfor ~}
  node_selector: "${instance_type}"

