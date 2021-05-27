param PrivEndpointName string
param region string
param tags object
// param vnetID string
param snetID string
param pLinkServiceID string
// param privateDNSZoneName string 
param serviceLinkGroupIds array
// var webapp_dns_name = '.azurewebsites.net'
param privateDnsZonesId string


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

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZonesId
        }
      }
    ]
  }
}
