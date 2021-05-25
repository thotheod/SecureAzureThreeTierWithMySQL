param PrivEndpointName string
param region string
param tags object
param vnetID string
param snetID string
param pLinkServiceID string
param privateDNSZoneName string 
param serviceLinkGroupIds array
var webapp_dns_name = '.azurewebsites.net'


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: PrivEndpointName
  location: region
  tags: tags
  properties: {
    subnet: {
      id: snetID
    }
    privateLinkServiceConnections: [
      {
        name: 'pl-${PrivEndpointName}'
        properties: {
          privateLinkServiceId: pLinkServiceID
          groupIds: serviceLinkGroupIds
        }
      }
    ]
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZones.name}/${privateDnsZones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetID
    }
  }
}
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
}
