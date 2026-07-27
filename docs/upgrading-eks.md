# Upgrading EKS

> 💡 TLDR; Bumping this module to a new EKS/Kubernetes version touches nine separate pieces of version-coupled configuration. Miss one — especially the Cluster Autoscaler Helm chart — and you get a cluster that looks healthy while the autoscaler silently stops scaling.

This is an operational runbook for upgrading the EKS cluster version (and everything that is coupled to it). Read the [case study](#case-study-the-july-2026-incident) below before you skip a step.

## Summary table

| What to bump | Variable(s) | Where | How to choose the value |
| --- | --- | --- | --- |
| Kubernetes control plane | `eks_cluster_version` (root) / `cluster_version` (eks module) | `variables.tf`, `eks/variables.tf` | Check [AWS EKS supported versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) and deprecation notices |
| Cluster Autoscaler image | `eks_autoscaler_version` / `autoscaler_version` | `variables.tf`, `eks/variables.tf` | Match the CA minor to the k8s minor (e.g. `1.34.5` for k8s 1.34), then take the latest patch |
| Cluster Autoscaler Helm chart | `eks_autoscaler_chart_version` / `autoscaler_chart_version` | `variables.tf`, `eks/variables.tf` | Chart `appVersion` must match the CA minor — **do not decouple from the image bump** |
| AMI types | `eks_default_ami_type`, `eks_default_ami_type_arm` | `variables.tf`, `eks/variables.tf` | Confirm the new k8s version still supports these AMI types |
| `terraform-aws-modules/eks/aws` | module version constraint | `eks/main.tf` (currently `~> 20.8.4`) | Check the module's changelog supports the target `cluster_version` |
| `aws-ia/eks-blueprints-addons` | module version constraint | `eks/addons.tf` (currently `~> 1.22.0`) | Check compatibility; remember its default CA chart pin is stale |
| EBS CSI driver addon | none (unpinned, resolves to EKS default) | `eks/addons.tf` `eks_addons.aws-ebs-csi-driver` | Confirm the resolved addon version post-apply supports the new k8s version |
| Terraform providers | `aws`, `kubernetes`, `helm` constraints | `versions.tf` | Confirm `kubernetes` provider supports the new API skew |
| Examples / README | none (docs/refs) | `examples/`, `README.md`, `docs/README.md` | Bump the `?ref=vX.Y.Z` tag after tagging the release |

---

## 1. Kubernetes control plane version

Variable: `eks_cluster_version` (root) / `cluster_version` (eks module), default `"1.34"`.

Before bumping, check the [AWS EKS supported Kubernetes versions](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) page for the target version's release notes and any deprecated/removed APIs. EKS enforces its own extended-support and end-of-life schedule independent of upstream Kubernetes — verify the version you're moving to (and the one you're moving away from) is still standard-supported, not just "available."

## 2. Cluster Autoscaler image

Variable: `eks_autoscaler_version` (root) / `autoscaler_version` (eks module), default `"1.34.5"`.

Cluster Autoscaler versioning tracks Kubernetes minors 1:1 — CA `1.34.x` is built and tested against k8s `1.34`. To find the latest available patch for a target minor:

```bash
gh api "repos/kubernetes/autoscaler/git/matching-refs/tags/cluster-autoscaler-1.34" --jq '.[].ref'
```

**Gotcha:** this variable does not flow to the deployment on its own. `eks/addons.tf` passes it explicitly as `image_tag_override = "v${var.autoscaler_version}"` on the `cluster_autoscaler` block inside the `eks_blueprints_addons` module. See [Helm `set` beats `values`](#helm-set-beats-values) below for why that override is mandatory.

## 3. Cluster Autoscaler Helm chart

Variable: `eks_autoscaler_chart_version` (root) / `autoscaler_chart_version` (eks module), default `"9.53.0"`.

**This is the most important variable to bump and the easiest to forget.** The chart renders the CA's RBAC (`ClusterRole`). A new CA image paired with an old chart means the new image's informers are missing permissions — see the [case study](#case-study-the-july-2026-incident).

To pick the right chart version, fetch the chart index and match `appVersion` to the CA minor you picked in step 2:

```bash
curl -s https://kubernetes.github.io/autoscaler/index.yaml | \
  yq '.entries."cluster-autoscaler"[] | select(.appVersion == "1.34.2") | .version'
# e.g. chart 9.53.0 -> appVersion 1.34.2
```

To verify a candidate chart's `ClusterRole` actually has what the new CA image needs before pinning it, pull the release tarball and inspect the template directly:

```bash
curl -sL -o cluster-autoscaler.tgz \
  https://github.com/kubernetes/autoscaler/releases/download/cluster-autoscaler-chart-9.53.0/cluster-autoscaler-9.53.0.tgz
tar xzf cluster-autoscaler.tgz
cat cluster-autoscaler/templates/clusterrole.yaml
```

## 4. AMI types

Variables: `eks_default_ami_type` (default `AL2023_x86_64_STANDARD`) and `eks_default_ami_type_arm` (default `AL2023_ARM_64_STANDARD`).

Confirm the new k8s version still supports these AMI types before bumping — AL2 AMIs stopped being supported at k8s 1.32; the 1.34 migration moved this module's defaults to AL2023. Individual node pools can override the default per-pool via `ami_type` in `eks_node_pools` / `node_pools` (`null` means "use the module default").

## 5. `terraform-aws-modules/eks/aws` version

Pinned in `eks/main.tf` (`module "eks"`), currently `~> 20.8.4`. Check the [module's changelog/releases](https://github.com/terraform-aws-modules/terraform-aws-eks/releases) to confirm it supports the target `cluster_version` before bumping the control plane — new k8s minors are sometimes gated behind a minimum module version.

## 6. `aws-ia/eks-blueprints-addons` version

Pinned in `eks/addons.tf` (`module "eks_blueprints_addons"`), currently `~> 1.22.0`. This module deploys the Cluster Autoscaler Helm release and the `aws-ebs-csi-driver` addon. Its own default CA chart pin is stale — even in `v1.24.3` upstream defaults to chart `9.35.0` — which is exactly why `eks/addons.tf` overrides `chart_version` explicitly instead of relying on the addon's default.

## 7. EBS CSI driver

Configured under `eks_addons.aws-ebs-csi-driver` in `eks/addons.tf` with no version pinned, so it resolves to the EKS default addon version for the cluster version at apply time. After bumping `cluster_version`, re-check (post-apply) which addon version was actually resolved and confirm it supports the new k8s version — there is no explicit version to bump here, only a resolved value to verify.

## 8. Terraform providers

Declared in `versions.tf`:

- `aws` `~> 5.40`
- `kubernetes` `>= 2.25.2`
- `helm` `>= 2.9, < 3.0`

The `kubernetes` provider in particular must support the new API version skew introduced by the target k8s version. Bump the constraint if the provider's own compatibility matrix requires it.

## 9. Examples and README

Everything under `examples/` uses `source = "../.."`, so CI validates the working tree directly — no extra bump needed there beyond whatever variables you changed above.

The usage snippets in `README.md` and `docs/README.md` pin a released tag (`?ref=vX.Y.Z`). Bump those tags only after you've tagged the release that contains the upgrade — not before.

---

## Critical gotchas

### Helm `set` beats `values`

`eks_blueprints_addons` passes `awsRegion`, `autoDiscovery.clusterName`, `image.tag`, and `rbac.serviceAccount.name` to the chart as Helm `set` entries. Helm `set` values always win over anything in the `values` template (`eks/helm/cluster-autoscaler.yaml.tpl`), no matter what that template says.

If `image_tag_override` is not passed, the blueprints module computes the image tag itself and falls back to `v<cluster_version>.0` for minors it doesn't recognize — silently ignoring `autoscaler_version` entirely. This is why `eks/addons.tf` passes `image_tag_override = "v${var.autoscaler_version}"`. Do not remove it.

### The real ServiceAccount is `cluster-autoscaler-sa`

The Cluster Autoscaler pod actually runs under the blueprints-managed ServiceAccount `cluster-autoscaler-sa`, with an IRSA role created by the blueprints module itself. The top-level `serviceAccount:` block and `image:` block in `eks/helm/cluster-autoscaler.yaml.tpl`, along with `aws_iam_role.cluster_autoscaler` in `eks/iam.tf`, are legacy/dead configuration — the chart reads `rbac.serviceAccount.*`, not the top-level `serviceAccount:` key. This is pending cleanup; don't assume editing those blocks changes anything at runtime.

### RBAC requirements grow with client-go

Each new CA release is built against a newer `client-go`, and newer `client-go` releases sometimes register new informers (e.g. `VolumeAttachment` support landed in CA >= 1.32). CA blocks on a full informer cache sync **before** it enters its scaling loop. One missing RBAC permission is enough to make it a healthy-looking no-op forever — no crash, no restart, just silence.

---

## Case study: the July 2026 incident

**Symptoms:** the second ZooKeeper pod sat `Pending` for over an hour. The Cluster Autoscaler pod was `Running`/`Ready` with 0 restarts. ASGs were correctly tagged for autodiscovery. CloudTrail showed CA calling the AWS API exactly once at startup to discover the ASGs, then making **zero** further AWS calls — no `SetDesiredCapacity`, no STS credential refresh, nothing.

**Log line:**

```
Failed to watch *v1.VolumeAttachment: volumeattachments.storage.k8s.io is forbidden:
User "system:serviceaccount:kube-system:cluster-autoscaler-sa" cannot list resource "volumeattachments"
```

**Root cause:** the EKS cluster (and CA image) had been bumped to 1.34, but the Helm chart was left at the blueprints-module default, `9.35.0`. That chart's `ClusterRole` predates `volumeattachments` support and never granted it. The new CA image's `VolumeAttachment` informer could not sync, so CA never finished its startup cache sync and never entered its scaling loop — while still reporting as a healthy, running pod. This is a known upstream issue: [kubernetes/autoscaler#7663](https://github.com/kubernetes/autoscaler/issues/7663), fixed in chart `9.47.0`.

**Fix:** pin `autoscaler_chart_version` >= `9.47.0`. The module now defaults to `9.53.0`.

**Lesson:** the image and the chart must always be bumped together. A Cluster Autoscaler that is `Running`/`Ready` but makes no AWS API calls after startup is not idle — it is dead.

---

## Post-upgrade verification checklist

Run all of these after every version bump, not just the ones you think you touched.

```bash
# 1. CA logs must be clean of RBAC/watch errors
kubectl -n kube-system logs deploy/cluster-autoscaler-aws-cluster-autoscaler \
  | grep -iE "forbidden|failed to watch"
# expect: no output

# 2. ClusterRole actually has the resources the new CA version needs
kubectl get clusterrole cluster-autoscaler-aws-cluster-autoscaler -o yaml
```

- **Functional scale test:** schedule a pod that doesn't fit on any current node and confirm the target ASG's desired capacity rises, and that CloudTrail shows a `SetDesiredCapacity` call made by the Cluster Autoscaler IAM role. Silence in CloudTrail after startup means the scaling loop is dead, even if the pod looks healthy.
- **`terraform plan`:** the diff should contain only the version bumps you intended — nothing else should be drifting.
- **CI green:** `fmt`, `validate` (all modules), `tflint`, `trivy`, and all `examples/` must pass.
