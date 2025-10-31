# Proxmox Terraform

A [Terraform](https://developer.hashicorp.com/terraform) module for creating a
[Talos Linux](https://www.talos.dev/) cluster of [Proxmox](https://www.proxmox.com/)
virtual machines.

## Prerequisites

The following assumes that you have an existing Proxmox environment and that you
have the Terraform CLI installed (see [References](#references) for links to
install guides).

## Getting Started

The first thing you'll want to do is set up a `terraform@pve` user with the
appropriate permissions and generate an API token that Terraform can use for
authentication:

```bash
# create a role and user
pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.GuestAgent.Audit VM.Migrate VM.PowerMgmt SDN.Use"
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role Terraform -privsep 0

# create a token: terraform@pve!tftoken
pveum user token add terraform@pve tftoken
```

Next, initialize terraform (`terraform init`), copy
[terraform.tfvars.example](./terraform.tfvars.example) to `terraform.tfvars` and
set the following values:

* `pve_token_secret` - the API token generated above (should look like a UUID)
* `pve_api_url` - the URL for your Proxmox environment's API; this should include
the path `/api2/json`
* `pve_controlplane_nodes` / `pve_worker_nodes` - lists of objects describing
the nodes you want to create and what Proxmox nodes/datastores they should use
* `talos_cluster_name` - the name you'd like your Talos cluster to have
* (optional) `talos_cluster_endpoint` - the Kubernetes controlplane endpoint for
the cluster; if left unset, this will default to using the IP address of the
first controlplane node created

As you're iterating on these changes you can take a look at what Terraform
intends to do using:

```bash
terraform plan
```

Once the plan is to your satisfaction, you can apply it using:

```bash
terraform apply
```

After your cluster is up-and-running, you can generate config files using:

```bash
# generate a talosctl config
terraform output -raw talosconfig

# generate a kubectl config
terraform output -raw kubeconfig
```

## Notes

I had to do some fairly tortuous stuff (time_sleeps, http gets) to work around
race conditions w/rt node (re)boots and the QEMU agent being available to
retrive IP addresses from VMs. This could probably use a little refactoring in
future, but for now it works. (see also: [TODO.md](./TODO.md))

## References

* [Talos Kubernetes on Proxmox using OpenTofu](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/)
* [bpg/proxmox Terraform provider](https://registry.terraform.io/providers/bpg/proxmox/latest)
* [siderolabs/talos Terraform Provider](https://registry.terraform.io/providers/siderolabs/talos/latest)
* [Proxmox "Get Started" guide](https://www.proxmox.com/en/products/proxmox-virtual-environment/get-started)
* [Terraform install guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [Talos Linux](https://www.talos.dev/)
