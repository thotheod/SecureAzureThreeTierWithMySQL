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
    subnets: [
      {
        name: snetDefault.name
        properties: {
          addressPrefix: snetDefault.subnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      } 
      {
        name: snetWAF.name
        properties: {
          addressPrefix: snetWAF.subnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: snetWS.name
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
      }
      {
        name: snetAdmin.name
        properties: {
          addressPrefix: snetAdmin.subnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: snetBastion.name
        properties: {
          addressPrefix: snetBastion.subnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }  
}


output vnetID string = vnet.id
output snetDefaultID string = vnet.properties.subnets[0].id
output snetWAFID string = vnet.properties.subnets[1].id
output snetWSID string = vnet.properties.subnets[2].id
output snetAdminID string = vnet.properties.subnets[3].id
output snetBastionID string = vnet.properties.subnets[4].id
