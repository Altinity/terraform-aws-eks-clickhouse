# Review (Ronda 2): `terraform-aws-eks-clickhouse`

Segunda pasada de review después de aplicar los fixes de la ronda 1.

---

## 1. Falta validación: pool "clickhouse" requerido cuando se instala el cluster

**Severidad: P1** | **`main.tf:74`** + **`variables.tf:189-195`**

```hcl
# main.tf:74
clickhouse_cluster_instance_type = [for np in var.eks_node_pools : np.instance_type if startswith(np.name, "clickhouse")][0]
```

La validación actual de `eks_node_pools` solo verifica que los nombres empiecen con `"clickhouse"` o `"system"`, pero no garantiza que exista al menos un pool `"clickhouse"`. Un usuario podría definir solo pools `"system"` y setear `install_clickhouse_cluster = true`. Esto causa un error críptico de índice fuera de rango en `terraform plan`.

**Escenario que falla:**
```hcl
install_clickhouse_cluster = true

eks_node_pools = [
  { name = "system", instance_type = "t3.large", desired_size = 1, max_size = 3, min_size = 1 }
]
# Error: "index 0 out of range for list with 0 elements"
```

**Fix sugerido:** Agregar una segunda validation en `eks_node_pools` o usar un precondition en el módulo `clickhouse_cluster`.

---

## 2. `AmazonEKSServicePolicy` deprecated

**Severidad: P1** | **`eks/iam.tf:105-108`**

```hcl
resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
```

`AmazonEKSServicePolicy` fue deprecated por AWS en 2021. Todos sus permisos ya están incluidos en `AmazonEKSClusterPolicy` (que ya se attacha en línea 100-103). La policy deprecated sigue existiendo en AWS por backwards compatibility, pero:

- AWS ya no la lista en la documentación oficial del [EKS service role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)
- Podría ser removida en el futuro
- Cuentas nuevas o regiones nuevas podrían no tenerla disponible

**Fix sugerido:** Eliminar el resource `eks_service_policy_attachment` completo.

---

## 3. Exec credential API `v1beta1` → `v1`

**Severidad: P2** | **`main.tf:10,21`** + **`clickhouse-cluster/load-balancer.tf:20`**

```hcl
# main.tf (providers kubernetes y helm)
api_version = "client.authentication.k8s.io/v1beta1"

# clickhouse-cluster/load-balancer.tf (kubeconfig template)
apiVersion: client.authentication.k8s.io/v1beta1
```

`v1beta1` del exec credential plugin sigue funcionando, pero `v1` es GA desde Kubernetes 1.22 y es lo que AWS recomienda para versiones recientes de EKS. El módulo usa EKS 1.34 por default.

**Contexto importante:** Esto NO es lo mismo que la deprecation de APIs del API server. El exec credential plugin `v1beta1` aún funciona en client-go. Sin embargo:
- AWS CLI soporta `v1` desde v1.24.0 / v2.7.0 (2022)
- Terraform kubernetes provider >= 2.25.2 (requerido por el módulo) lo soporta
- Algunos linters y herramientas de seguridad lo marcan como deprecated

**Riesgo de cambiar:** Bajo. Requiere AWS CLI relativamente reciente, pero cualquier versión de los últimos 3 años funciona.

**Fix sugerido:** Cambiar a `v1` en los 3 lugares.

---

## 4. Archivo temporal de kubeconfig no se limpia

**Severidad: P2** | **`clickhouse-cluster/load-balancer.tf:40`**

```bash
KUBECONFIG_PATH=$(mktemp)
cat > "$KUBECONFIG_PATH" <<'KUBECONFIG'
...
KUBECONFIG
# ... script continúa y termina sin rm
```

El `mktemp` crea un archivo en `/tmp` con el kubeconfig del cluster (endpoint + CA cert). El script nunca lo elimina. En entornos de CI/CD compartidos o máquinas multi-usuario, esto deja credenciales del cluster accesibles.

**Matiz:** El kubeconfig usa `aws eks get-token` para auth, así que sin credenciales AWS no sirve de mucho. Pero el CA cert y endpoint sí son información sensible.

**Fix sugerido:** Agregar un `trap` al inicio del script:
```bash
KUBECONFIG_PATH=$(mktemp)
trap 'rm -f "$KUBECONFIG_PATH"' EXIT
```

---

## 5. Typo: "wich" → "which"

**Severidad: P3** | **`clickhouse-cluster/load-balancer.tf:33`**

```hcl
# This is a "hack" wich waits for the ClickHouse cluster...
```

Debería ser "which".

---

## Resumen

| # | Issue | Severidad | Breaking? |
|---|-------|-----------|-----------|
| 1 | Falta validación pool "clickhouse" | P1 | No |
| 2 | `AmazonEKSServicePolicy` deprecated | P1 | No (*) |
| 3 | Exec credential `v1beta1` → `v1` | P2 | No (**) |
| 4 | Temp kubeconfig no se limpia | P2 | No |
| 5 | Typo "wich" | P3 | No |

(*) Eliminar una policy attachment es un cambio de IAM. Terraform hará un `destroy` del attachment, que es seguro si `AmazonEKSClusterPolicy` ya cubre los permisos.

(**) Requiere AWS CLI >= 1.24.0 / 2.7.0. Cualquier instalación de los últimos 3 años cumple.
