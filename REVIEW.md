# Review Completa: `terraform-aws-eks-clickhouse`

## Estructura General

El módulo tiene buena separación en 3 submódulos (`eks`, `clickhouse-operator`, `clickhouse-cluster`) con un root module que los orquesta. La estructura es clara y el scope está bien definido.

---

## 1. BUGS

### 1.1 Availability Zones default son REGIONES, no AZs
**`eks/variables.tf:46-52`** — Los defaults son `us-east-1`, `us-east-2`, `us-east-3`. Eso son **regiones**, no availability zones. Debería ser `us-east-1a`, `us-east-1b`, `us-east-1c`.

```hcl
# Actual (incorrecto)
default = ["us-east-1", "us-east-2", "us-east-3"]

# Correcto
default = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### 1.2 `merge()` con `null` en labels
**`eks/main.tf:67`** — `merge(np.labels, local.labels)` fallará con error si `np.labels` es `null`. El campo `labels` es `optional(map(string))` y su default implícito es `null`, no `{}`.

```hcl
# Fix: usar coalesce
labels = merge(coalesce(np.labels, {}), local.labels)
```

### 1.3 Variable duplicada/muerta: `eks_autoscaler_replicas`
**`variables.tf:121-131`** — Existen dos variables para lo mismo:
- `eks_autoscaler_replicas` (línea 121) — **no se usa en ningún lado**
- `autoscaler_replicas` (línea 127) — esta es la que se pasa al módulo EKS

La variable `eks_autoscaler_replicas` es código muerto.

---

## 2. SEGURIDAD

### 2.1 API Server de EKS público a todo Internet
**`eks/main.tf:154-156`** + **`variables.tf:234-238`**

```hcl
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = var.public_access_cidrs  # default: ["0.0.0.0/0"]
```

El control plane de EKS queda expuesto a **todo Internet** por default. Para producción esto es un riesgo serio. Recomiendo que el default de `public_access_cidrs` sea más restrictivo, o al menos agregar una validación/warning.

### 2.2 ~~Sin encryption de secrets en EKS~~ (RESUELTO)
Se agregó la variable `eks_enable_secrets_encryption` (default `false`) para habilitar envelope encryption con KMS. Documentado en `docs/prod-ready.md`.

### 2.3 ~~Sin logging del cluster~~ (RESUELTO)
Se agregó la variable `eks_cluster_enabled_log_types` (default `[]`) para habilitar logs del control plane. Documentado en `docs/prod-ready.md`.

### 2.4 Kubeconfig expuesto via `echo` en shell
**`clickhouse-cluster/load-balancer.tf:39-41`**

```bash
echo '${local.kubeconfig}' > $KUBECONFIG_PATH
```

El kubeconfig (que contiene el endpoint y cert del cluster) queda visible en `ps aux` y potencialmente en logs de Terraform. Mejor usar `cat <<EOF >` o un `heredoc` cerrado.

### 2.5 Falta condición `aud` en OIDC trust policy
**`eks/iam.tf:135-151`** — La policy del EBS CSI driver solo valida `sub` pero no `aud`. AWS recomienda agregar también:

```hcl
condition {
  test     = "StringEquals"
  variable = "${...}:aud"
  values   = ["sts.amazonaws.com"]
}
```

Lo mismo aplica para la trust policy del cluster autoscaler (línea 207-230).

### 2.6 Autoscaler IAM policy con `Resource: "*"`
**`eks/iam.tf:170-205`** — Ambos statements del autoscaler usan `Resource: "*"`. Idealmente se debería limitar al menos el segundo statement (que permite `SetDesiredCapacity` y `TerminateInstanceInAutoScalingGroup`) a los ASGs del cluster usando tags como condición.

### 2.7 Password en plaintext en Helm values
**`clickhouse-cluster/main.tf:53`** — El password se pasa directo al template. Esto queda almacenado en plaintext en el Terraform state. Es inherente a Terraform, pero debería documentarse como una limitación y recomendar usar un secrets manager externo para producción.

---

## 3. DISEÑO Y ARQUITECTURA

### 3.1 Single NAT Gateway = single point of failure
**`eks/vpc.tf:24`** — `single_nat_gateway = true`. Para producción, si la AZ del NAT Gateway cae, todos los nodos privados pierden conectividad a Internet. Recomiendo agregar una variable `single_nat_gateway` para que el usuario pueda configurar un NAT por AZ.

### 3.2 VPN Gateway acoplado al NAT Gateway
**`eks/vpc.tf:22`** — `enable_vpn_gateway = !var.enable_nat_gateway`

No hay razón lógica para que deshabilitar NAT automáticamente habilite un VPN Gateway. Son conceptos independientes.

### 3.3 Acoplamiento frágil con `node_pools[0]`
**`main.tf:70`**

```hcl
clickhouse_cluster_instance_type = var.eks_node_pools[0].instance_type
```

Si el usuario reordena los node pools, el instance_type del cluster ClickHouse cambia silenciosamente. Mejor usar una variable dedicada o buscar el pool por nombre:

```hcl
# Ejemplo: buscar el primer pool que empiece con "clickhouse"
[for np in var.eks_node_pools : np.instance_type if startswith(np.name, "clickhouse")][0]
```

### 3.4 Node groups nombrados por índice
**`eks/main.tf:125`** — `"node-group-${tostring(idx)}"`

Si se cambia el orden de los node pools o se agrega uno al medio, los índices cambian y Terraform forzará la **recreación** de todos los node groups afectados. Mejor usar un nombre estable:

```hcl
"${np.name}-${replace(zone, var.region, "")}" => { ... }
```

### 3.5 Falta validación de match entre CIDRs y AZs
No hay validación de que `length(eks_private_cidr) == length(eks_availability_zones)` ni para `eks_public_cidr`. El módulo VPC fallará con errores confusos si no coinciden.

---

## 4. CALIDAD DE CÓDIGO

### 4.1 Typo: "recommeded"
**`eks/variables.tf:57`** y **`variables.tf:199`** — Debería ser "recommended".

### 4.2 Variable `eks_availability_zones` sin description
**`variables.tf:224-225`** — `description = ""` está vacío.

### 4.3 Output `cluster_node_pools` sin description
**`outputs.tf:38-40`** — Falta `description`.

### 4.4 Variables no usadas en `clickhouse-cluster`
**`clickhouse-cluster/variables.tf:65-87`** — Las variables `k8s_cluster_endpoint`, `k8s_cluster_name`, `k8s_cluster_region`, `k8s_cluster_certificate_authority` se pasan al módulo pero solo se usan en `load-balancer.tf` para construir un kubeconfig para el `null_resource`. Si `clickhouse_cluster_enable_loadbalancer = false`, ninguna de estas variables se usa realmente.

### 4.5 Inconsistencia de naming
- Root module usa prefijo `eks_` para variables EKS, pero `autoscaler_replicas` no lo tiene
- `clickhouse_name` existe solo en el submódulo pero no se expone como variable del root module (hardcodeado implícitamente al default `"eks"`)

### 4.6 Examples sin version pinning
**`examples/default/main.tf:11`** — `source = "github.com/Altinity/terraform-aws-eks-clickhouse"` sin `?ref=vX.Y.Z`. Cualquiera que use el example apuntará a `HEAD` de master.

---

## 5. RESILIENCIA Y PRODUCCIÓN

### 5.1 Sin `reclaim_policy = "Retain"` como opción
**`eks/addons.tf:49`** — La StorageClass `gp3-encrypted` usa `reclaim_policy = "Delete"`. Para datos de ClickHouse en producción, borrar el PV al borrar el PVC puede causar pérdida de datos irrecuperable. Debería ser configurable.

### 5.2 Sin `wait` explícito en Helm releases
Los `helm_release` del operator y cluster no configuran `wait = true` (default) ni `timeout` customizados. Si el deploy tarda más de 5 minutos (default), fallará silenciosamente.

### 5.3 Sin node group `min_size >= 1` para system
Los defaults tienen `min_size = 0` para el pool `system`. Si el autoscaler escala a 0, los workloads de sistema (CoreDNS, etc.) quedarán sin nodos.

---

## 6. RESUMEN DE PRIORIDADES

| Prioridad | Issue | Impacto |
|-----------|-------|---------|
| **P0** | AZs default son regiones en submódulo eks | Falla en deploy |
| **P0** | `merge()` con labels null | Runtime error |
| **P1** | API server público a 0.0.0.0/0 | Seguridad |
| ~~**P1**~~ | ~~Sin encryption de secrets en EKS~~ | ~~Seguridad~~ (RESUELTO) |
| ~~**P1**~~ | ~~Sin cluster logging~~ | ~~Observabilidad~~ (RESUELTO) |
| **P1** | Falta condición `aud` en OIDC | Seguridad |
| **P2** | Node groups por índice (recreación) | Estabilidad |
| **P2** | Single NAT Gateway | Disponibilidad |
| **P2** | Acoplamiento con node_pools[0] | Usabilidad |
| **P2** | Variable muerta `eks_autoscaler_replicas` | Mantenibilidad |
| **P2** | StorageClass sin opción Retain | Datos |
| **P3** | Typos, descriptions vacías | Documentación |
| **P3** | VPN gateway acoplado a NAT | Diseño |
| **P3** | Examples sin version pinning | Usabilidad |

---

En general el módulo está bien estructurado y cumple su propósito como quickstart para ClickHouse en EKS. Los issues P0 son bugs que deberían arreglarse ya. Los P1 son críticos para cualquier uso que no sea puramente dev/testing.
