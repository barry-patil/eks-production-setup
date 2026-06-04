# EKS Production Setup

This is how I set up production-grade EKS clusters. It's gone through a few iterations across different companies — the version here reflects what I settled on after managing clusters at Kaleyra, NCS, and Cognam.

The biggest lesson: don't treat EKS as just "managed Kubernetes." The networking, IAM, and node group design decisions matter a lot more than most tutorials suggest, and they're painful to change later.

## What's in here

```
terraform/
  modules/
    vpc/    — VPC, subnets (public + private), NAT gateways per AZ
    eks/    — EKS cluster, node groups, add-ons
    iam/    — Cluster role, node role, IRSA roles
  environments/
    dev/    — Lower cost setup, single NAT gateway
    prod/   — HA setup, NAT per AZ, larger nodes
k8s/
  rbac/           — ClusterRoles for dev team vs ops team
  autoscaling/    — Cluster Autoscaler deployment
  monitoring/     — kube-state-metrics, metrics-server
helm/
  values/         — Overrides for common Helm charts
```

## Design decisions worth explaining

**Two node groups (system + application)**

System components (CoreDNS, autoscaler, monitoring agents) live on dedicated nodes with a `CriticalAddonsOnly` taint. This prevents application pods from accidentally landing on system nodes and starving them for resources. I learned this the hard way when a misconfigured HPA scaled up a batch job and took down DNS on a Friday afternoon.

**Private subnets for worker nodes**

Nodes sit in private subnets and communicate with the control plane via an internal endpoint. Public access is left on for kubectl from developer machines but locked down by security group. In stricter environments, you'd flip `endpoint_public_access` to false and go fully VPN-gated.

**NAT Gateway per AZ in prod**

Costs more, but worth it. Cross-AZ NAT traffic adds up at scale, and losing the single NAT during an AZ failure takes down all outbound traffic from private subnets.

## Getting started

```bash
# Set up prod cluster
cd terraform/environments/prod
terraform init
terraform plan
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --name pratik-prod --region ap-south-1

# Apply RBAC
kubectl apply -f k8s/rbac/

# Deploy cluster autoscaler
kubectl apply -f k8s/autoscaling/cluster-autoscaler.yaml
```

## Node sizing reference

| Environment | System nodes | App nodes | Max scale |
|------------|-------------|-----------|-----------|
| dev        | t3.small x2 | t3.medium | 5         |
| prod       | t3.medium x2 | t3.large | 10        |

The autoscaler uses `least-waste` expander — it picks the node group that wastes the least CPU/memory when scaling up. In practice this avoids over-provisioning on burst traffic.

## IAM and IRSA

Service accounts that need AWS access (external-dns, aws-load-balancer-controller, EBS CSI driver) use IRSA rather than instance profiles. This gives per-pod IAM scoping instead of granting every pod on a node the same permissions.

The IAM module handles OIDC provider setup and the trust policy for each service account.
