param name string
param region string
param tags object
param vnetAddressSpace string 
param enableVmProtection bool = false
param enableDdosProtection bool = false
param snetDefault object
param snetWAF object
param snetWS object
param snetAdmin object
param snetBastion object


resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    enableVmProtection: enableVmProtection
    enableDdosProtection: enableDdosProtection
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }    
  }
}

resource subnetDefault 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${snetDefault.name}'
  properties: {
    addressPrefix: snetDefault.subnetPrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource subnetWAF 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${snetWAF.name}'
  properties: {
    addressPrefix: snetWAF.subnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    subnetDefault
  ]
}

resource subnetWebServers 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${snetWS.name}'
  properties: {
    addressPrefix: snetWS.subnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
  }
  dependsOn: [
    subnetWAF
  ]
}

resource subnetAdmin 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${snetAdmin.name}'
  properties: {
    addressPrefix: snetAdmin.subnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    subnetWebServers
  ]
}

resource subnetBastion 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnet.name}/${snetBastion.name}'
  properties: {
    addressPrefix: snetBastion.subnetPrefix
    privateEndpointNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    subnetAdmin
  ]
}


output vnetID string = vnet.id
output snetDefaultID string = subnetDefault.id
output snetWAFID string = subnetWAF.id
output snetWSID string = subnetWebServers.id
output snetAdminID string = subnetAdmin.id
output snetBastionID string = subnetBastion.id
