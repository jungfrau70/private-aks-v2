# Private AKS Workshop — Enterprise-Grade Kubernetes on Azure

> Builds a **production-ready Private AKS environment** step by step, covering network isolation, identity, ingress, storage, database, CI/CD, monitoring, and operational troubleshooting.

---

## Repository Structure

```
private-aks-v2/
├── 1_azcli/          # Manual setup via Azure CLI (step-by-step scripts)
├── 2_terraform/      # Terraform IaC — full modular deployment
├── 3_monitoring/     # AKS health-check & troubleshooting scripts (Ops)
└── 4_ts_db/          # DB connectivity diagnosis from AKS pods (Hub VNet PostgreSQL/Oracle)
```

---

## Full Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                   Private AKS Workshop — Azure Architecture              │
├──────────────────────────────────────────────────────────────────────────┤
│ [Identity & RBAC Layer]                                                  │
│   Azure AD (Entra ID) — Users / Groups / Managed Identity               │
│   RBAC: Operators / Admins / ClusterAdmins / Developers                 │
├──────────────────────────────────────────────────────────────────────────┤
│ [Network Layer] — Hub-Spoke-Storage (3 VNets)                           │
│                                                                          │
│  Hub VNet (10.0.0.0/16)         Spoke VNet (10.1.0.0/16)               │
│  ├─ AzureBastionSubnet          ├─ AKS Subnet         (10.1.0.0/24)    │
│  ├─ JumpboxSubnet               ├─ App Gateway Subnet  (10.1.1.0/24)   │
│  ├─ ACR Subnet (private EP)     ├─ Endpoints Subnet    (10.1.2.0/24)   │
│  ├─ DB Subnet (PostgreSQL)      └─ LoadBalancer Subnet (10.1.3.0/24)   │
│  └─ Agent Subnet                                                        │
│                     Storage VNet (10.2.0.0/16)                          │
│                     └─ Storage Subnet (Azure Files)                     │
│                                                                          │
│   VNet Peering: Hub↔Spoke / Hub↔Storage / Spoke↔Storage                │
├──────────────────────────────────────────────────────────────────────────┤
│ [Compute & Ingress Layer]                                               │
│   Private AKS Cluster (API Server Private Endpoint)                     │
│   Application Gateway + AGIC (public ingress only via AGIC)            │
│   Jumpbox VM — kubectl access via Azure Bastion                         │
├──────────────────────────────────────────────────────────────────────────┤
│ [Security & Storage Layer]                                              │
│   Azure Container Registry  — Private Endpoint (Hub VNet)              │
│   Azure Key Vault            — Private Endpoint (Hub VNet) + RBAC      │
│   Azure Files (Storage VNet) — Private Endpoint                        │
├──────────────────────────────────────────────────────────────────────────┤
│ [Data Layer]                                                            │
│   PostgreSQL Flexible Server — Private Endpoint in Hub VNet             │
│   Private DNS: privatelink.postgres.database.azure.com                 │
├──────────────────────────────────────────────────────────────────────────┤
│ [CI/CD & Automation Layer]                                              │
│   GitHub Actions — OIDC (Workload Identity Federation, no secrets)     │
│   Terraform — modular IaC (Azure Storage remote state backend)         │
├──────────────────────────────────────────────────────────────────────────┤
│ [Observability Layer]                                                   │
│   Log Analytics Workspace — AKS / App Gateway / Network diagnostics    │
│   Monitor Action Groups — email alerts on threshold breach              │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Module 1 — Azure CLI Manual Setup (`1_azcli/`)

### Purpose
Step-by-step Azure CLI scripts that build the same environment **manually**, making each resource dependency and configuration visible. Useful for learning and live demos.

### Script Flow

```
1_1 Azure AD users
1_2 Azure AD groups
1_3 Subscription RBAC
      ↓
2_1 Azure File Share (Storage VNet)
2_2 RBAC for File Share
2_3 Access verification
      ↓
3_1 Hub VNet + subnets + NSGs
3_2 Spoke VNet + subnets + NSGs
3_3 VNet Peering (Hub↔Spoke↔Storage)
3_4 Bastion + Jumpbox
3_5 Application Gateway
3_6 ACR (private endpoint)
3_7 Key Vault (private endpoint)
      ↓
4_1 Bastion/Jumpbox access test
      ↓
5_1 Private AKS cluster
5_2 Azure AD RBAC for AKS
5_3 AKS Private Endpoint
5_4 Private Link for API Server
      ↓
6_1 kubeconfig (from Jumpbox)
6_2 RBAC: AKS → ACR (acrpull)
6_3 RBAC: AKS → Key Vault (Secrets User)
      ↓
7_1 Build app image → push to ACR
7_2 Deploy app to AKS (kubectl)
7_4 AGIC Ingress resource
      ↓
8_1 Pod deployment with Key Vault secret injection
```

### Architectural Point
> "The CLI approach builds the environment imperatively, making each dependency explicit. This is how you understand *why* each resource must exist before the next one — the same logic that drives the Terraform module dependency graph in `2_terraform/`."

---

## Module 2 — Terraform IaC (`2_terraform/`)

### Purpose
Full declarative deployment of the entire environment using Terraform with a modular structure. Remote state is stored in Azure Blob Storage.

### Terraform Module Map

```
main.tf
├── module.resource_groups     ← Hub / Spoke / Storage RGs
├── module.azure_ad            ← Users, groups, service principals
├── module.network             ← All VNets, subnets, NSGs, peering
├── module.storage             ← Azure Files + private endpoint
├── module.central_acr         ← ACR + private endpoint (Hub)
├── module.central_keyvault    ← Key Vault + private endpoint (Hub) + RBAC
├── module.app_gateway         ← Application Gateway + WAF policy
├── module.bastion             ← Azure Bastion (Standard SKU)
├── module.jumpbox             ← Jumpbox VM (auto-shutdown supported)
├── module.monitoring          ← Log Analytics + alerts + action groups
├── module.aks_identity        ← User-assigned managed identity per cluster
├── module.aks_cluster         ← Private AKS (AGIC add-on, RBAC, monitoring)
├── module.aks_dns             ← Private DNS Zone + VNet links
├── module.aks_rbac            ← ACR / Key Vault / AGIC role assignments
└── module.database            ← PostgreSQL Flexible Server (Hub VNet)
```

### Deployment Order (dependency chain)

```
resource_groups
      ↓
azure_ad  +  network
      ↓           ↓
storage      central_acr  central_keyvault  app_gateway  bastion  jumpbox
                   ↓              ↓               ↓
                        monitoring
                             ↓
                    aks_identity → aks_cluster → aks_dns → aks_rbac
                                        ↓
                                    database
```

### "Use Existing or Create" Pattern

The `terraform.tfvars` controls whether each resource layer is created or reused:

```hcl
use_existing_resource_group_hub    = false   # create Hub RG
use_existing_networks              = false   # create VNets
use_existing_acr                   = false   # create ACR
use_existing_keyvault              = false   # create Key Vault
use_existing_aks_cluster           = false   # create AKS
use_existing_postgresql            = false   # create PostgreSQL
```

Set to `true` for any layer that already exists — the module imports the existing resource instead of creating a duplicate.

### Quick Start

```bash
# Initialize with remote state backend
terraform init -backend-config=backend.conf

# Preview
terraform plan -var-file=terraform.tfvars

# Deploy all modules
terraform apply -var-file=terraform.tfvars

# Or use the staged deployment script (resolves count-dependency issues)
chmod +x apply-aks.sh && ./apply-aks.sh
```

### GitHub Actions CI/CD (OIDC — no stored secrets)

```
[git push → main]
      ↓
[GitHub Actions: .github/workflows/terraform-deploy.yml]
      ↓
  az login --federated-token (OIDC — no AZURE_CLIENT_SECRET)
      ↓
  terraform init + plan + apply
```

Required GitHub Secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

### Architectural Point
> "Each Terraform module maps to a real enterprise team boundary — platform team owns network/security, app team owns AKS/ACR/K8s manifests. The `use_existing_*` flags allow gradual adoption: brownfield environments can import existing resources without destroying and recreating them."

---

## Module 3 — AKS Operational Health Check (`3_monitoring/`)

### Purpose
Three tiers of check scripts for IT Ops teams — designed for minimal setup, quick execution, and clear output files.

### Script Tiers

| Tier | Target | Scripts | Use Case |
|------|--------|---------|----------|
| **24x7** | L1 Support (simple monitoring) | `24x7_aks_check.sh` + `.env` | Night-shift alerts, basic node/pod status |
| **aks_platform** | L2 Support (AKS platform) | `aks_check.sh` + `.env` | Cluster-level troubleshooting, control plane health |
| **aks_pod_check** | L2 Support (application) | `aks_pod.sh` + `.env` | Pod/container-level diagnosis, image, restart counts |

Each tier produces:
- Result log file (`*_aks*.log`) with interpretation
- Checklist (`*_checklist`) for systematic review
- Environment config file (`.env`) for cluster-specific settings

### Architectural Point
> "The three-tier structure mirrors real enterprise Ops escalation. L1 runs the 24x7 script on every alert; L2 platform engineers run the AKS platform scripts for control-plane and network issues; L2 app engineers run the pod check script for application-layer diagnosis."

---

## Module 4 — DB Connectivity Troubleshooting from AKS (`4_ts_db/`)

### Purpose
Diagnose connectivity issues between AKS pods (Spoke VNet) and databases (PostgreSQL / Oracle) on Hub VNet via VNet Peering + Private Endpoint.

### Diagnosis Flow

```
[AKS Pod] → outbound IP check (curl ifconfig.me)
      ↓
TCP port test (bash /dev/tcp) → is the network path open?
      ↓
DB client connection (psql / sqlplus) → does auth succeed?
      ↓
Session state queries (pg_stat_activity / v$session) → pool exhaustion?
      ↓
SNAT port exhaustion check (Azure Monitor Log Analytics)
      ↓
Packet capture (tcpdump) → RST/FIN/timeout analysis (Wireshark)
```

### Key Diagnosis Points

| Symptom | Check | Tool |
|---------|-------|------|
| Pod cannot reach DB at all | NSG, UDR, VNet Peering, Private DNS | `nc`, `/dev/tcp` |
| Outbound IP unexpected | NAT Gateway / LB Outbound type | `curl ifconfig.me` |
| Intermittent disconnects | SNAT port exhaustion, idle timeout | Azure Monitor KQL |
| Too many DB sessions | Connection pool misconfiguration | `pg_stat_activity` |
| Packet-level RST/FIN | Firewall, idle TCP timeout | `tcpdump` + Wireshark |

### Test Pod Deployment

```bash
# Deploy network diagnostic pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: network-multitool
spec:
  containers:
  - name: multitool
    image: praqma/network-multitool
    command: ["sleep", "3600"]
EOF

# Enter pod and run diagnostics
kubectl exec -it network-multitool -- bash
curl ifconfig.me
timeout 5 bash -c '</dev/tcp/<DB_PRIVATE_FQDN>/5432' && echo "OK" || echo "FAIL"
```

### Architectural Point
> "When AKS pods connect to databases via Private Endpoint, the Pod's source IP is NAT'd through the node's outbound path (Standard LB or NAT Gateway). SNAT port exhaustion is the most common cause of intermittent connection drops in production — monitor with `LoadBalancerSnatPortExhausted` in Azure Diagnostics Logs."

---

## Network Architecture — Detailed Subnet Map

### Hub VNet (10.0.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AzureBastionSubnet | 10.0.0.0/26 | Azure Bastion (required name, no NSG) |
| JumpboxSubnet | 10.0.0.64/26 | Jumpbox VM (no public IP) |
| AzureFirewallSubnet | 10.0.0.128/26 | Azure Firewall (optional) |
| ACR Subnet | 10.0.1.0/26 | ACR Private Endpoint |
| Agent Subnet | 10.0.1.64/26 | DevOps/CI agent VMs |
| DB Subnet | 10.0.5.0/24 | PostgreSQL Flexible Server |

### Spoke VNet (10.1.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AKS Subnet | 10.1.0.0/24 | AKS node pool |
| App Gateway Subnet | 10.1.1.0/24 | Application Gateway (AGIC) |
| Endpoints Subnet | 10.1.2.0/24 | Private Endpoints (Key Vault, etc.) |
| LoadBalancer Subnet | 10.1.3.0/24 | Internal Load Balancer |

### Storage VNet (10.2.0.0/16)

| Subnet | CIDR | Purpose |
|--------|------|---------|
| Storage Subnet | 10.2.1.0/24 | Azure Storage Private Endpoint |

---

## Access Patterns — Zero Trust Admin Access

```
[Developer workstation]
      │
      ▼  (Azure Portal or CLI)
[Azure Bastion — AzureBastionSubnet]
      │  TLS tunnel (no port 22 exposed to internet)
      ▼
[Jumpbox VM — JumpboxSubnet, no public IP]
      │  SSH (port 22 allowed only from JumpboxSubnet)
      ▼
[AKS API Server — Private Endpoint]
      │  kubectl (via kubeconfig from az aks get-credentials)
      ▼
[AKS pods / K8s resources]
```

> "The AKS API server has no public endpoint — all `kubectl` commands must originate from within the VNet (Jumpbox or CI agent). Azure Bastion provides the Zero Trust entry point: browser-based, MFA-inherited, no SSH key to manage."

---

## Security Design — Private Endpoint Architecture

```
[Internet]   → blocked for all private resources
      
[ACR]        → Private Endpoint in Hub VNet (10.0.1.0/26)
               Private DNS: privatelink.azurecr.io
               AKS pulls images via VNet only (acrpull RBAC on kubelet identity)

[Key Vault]  → Private Endpoint in Hub VNet
               Private DNS: privatelink.vaultcore.azure.net
               AKS workloads access secrets via Managed Identity + RBAC (no passwords)

[PostgreSQL] → Private Endpoint in Hub VNet (endpoints-subnet)
               Private DNS: privatelink.postgres.database.azure.com
               Accessible from AKS pods via VNet Peering
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Azure CLI | Latest | Resource provisioning + kubeconfig |
| Terraform | >= 1.0 | IaC deployment (`2_terraform/`) |
| kubectl | Latest | Kubernetes management |
| Helm | >= 3.0 | AGIC add-on, cert-manager |
| Docker | Latest | App image build + ACR push |

---

## Quick Reference — Key Outputs After Deployment

```bash
# Get AKS kubeconfig (must run from Jumpbox or VNet-connected machine)
az aks get-credentials \
  --resource-group rg-spoke \
  --name <AKS_CLUSTER_NAME> \
  --admin

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces

# Get Application Gateway public IP (ingress entry point)
az network public-ip show \
  --resource-group rg-spoke \
  --name <APPGW_PIP_NAME> \
  --query ipAddress -o tsv

# Check AGIC Ingress
kubectl get ingress -A
```

---

## Troubleshooting Quick Reference

| Issue | Root Cause | Resolution |
|-------|-----------|------------|
| `kubectl` times out | Not inside VNet (API server is private) | Use Jumpbox via Bastion |
| ACR pull fails | Missing `acrpull` role on kubelet identity | `az role assignment create` (handled by `aks_rbac` module) |
| Key Vault access denied | Managed Identity missing RBAC | Check `Key Vault Secrets User` assignment |
| AGIC Ingress not routing | App Gateway / AGIC pod misconfigured | `kubectl logs -n kube-system -l app=ingress-appgw` |
| PostgreSQL connection drops | SNAT port exhaustion | Check LB outbound rules; consider NAT Gateway |
| Terraform `count` error | AKS cluster ID unknown at plan time | Run `./apply-aks.sh` staged deployment script |

---

*Last updated: 2026-06-13 | Private AKS Workshop v2*
