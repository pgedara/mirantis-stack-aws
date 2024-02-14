// locals calculated before the provision run
locals {
  // combine the nodegroup definition with the platform data
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_ami[ngd.platform]) }
}

# PROVISION MACHINES/NETWORK
module "provision" {
  source = "../../provision"

  name = var.name
  tags = local.tags

  cidr                 = var.network.cidr
  public_subnet_count  = 1
  private_subnet_count = 0
  enable_vpn_gateway   = false
  enable_nat_gateway   = false

  // pass in a mix of nodegroups with the platform information
  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    ami : ngd.ami
    count : ngd.count
    type : ngd.type
    keypair_id : module.key.keypair_id
    root_device_name : ngd.root_device_name
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data
  } }

  // pass in ingroup information (could jsut consume var.ingresses, but this makes it clearer)
  ingresses = { for k, i in local.k0s_ingresses : k => {
    description = i.description
    nodegroups  = i.nodegroups,
    routes      = i.routes
  } }

  // Use the firewall rules which mix the defaults with the additional rules from var.)
  securitygroups = {
    "k0s" = {
      description  = "Common SG for all cluster machines"
      nodegroups   = [for n, ng in var.nodegroups : n]
      ingress_ipv4 = local.k0s_firewall_rules_ingress_ipv4,
      egress_ipv4  = local.k0s_firewall_rules_egress_ipv4
    }
  }
}

// locals calculated after the provision module is run, but before installation using launchpad
locals {
  // combine each node-group & platform definition with the provisioned nodes
  nodegroups = { for k, ngp in local.nodegroups_wplatform : k => merge({ "name" : k }, ngp, module.provision.nodegroups[k]) }
  ingresses  = { for k, i in local.k0s_ingresses : k => merge({ "name" : k }, i, module.provision.ingresses[k]) }
}
