param name string
param region string
param tags object
param appGwaySKU string 
param subnetID string
param pipID string
param minCapacity int = 1
param maxCapacity int = 10
param backendIPAddresses array = []
//   {
//     IpAddress: '10.0.0.4'
//   }
//   {
//     IpAddress: '10.0.0.5'
//   }
// ]


resource waf 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    sku: {
      name: appGwaySKU
      tier: appGwaySKU
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
      maxCapacity: maxCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetID
          }
        }
      }      
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipID
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'myBackendPool'
        properties: {
          backendAddresses: backendIPAddresses
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'myHTTPSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'myBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'myHTTPSettings')
          }
        }
      }
    ]
  }
}


// "id": "[resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', variables('applicationGateways_myAppGateway_name'), 'appGwPublicFrontendIp')]"
