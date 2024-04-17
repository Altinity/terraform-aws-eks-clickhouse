all:
  metadata:
    labels:
      application_group: ${name}

keeper:
  name: ${name}
  cluster: chk
  zones:
%{ for zone in zones ~}
    - ${zone}
%{ endfor ~}
  node_selector: "${instance_type}"
