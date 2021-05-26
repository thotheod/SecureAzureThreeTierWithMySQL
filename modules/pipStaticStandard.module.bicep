param name string
param region string
param tags object

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: name
  location: region
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output pipID string = publicIP.id
