// default module for Application Service Plan
param name string
param region string
param tags object
param serverFarmId string
param subnetId string
param webAppWithPrivateLink bool
var webapp_dns_name = '.azurewebsites.net'

resource webApp 'Microsoft.Web/sites@2020-12-01' = {
  name: name
  location: region
  kind: 'app,linux'
  tags: tags
  properties: {
    serverFarmId: serverFarmId
    reserved: true    
  }

}

// runtime configuration
resource webSiteConfigWeb 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${webApp.name}/web'
  kind: 'app,linux'
  properties: {
    linuxFxVersion: 'PHP|7.4'
    alwaysOn: true
  }
}

//app settings - DNS Entries
resource webSiteConfigAppSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${webApp.name}/appsettings'
  kind: 'app,linux'
  properties: {
    'WEBSITE_DNS_SERVER': '168.63.129.16'
    'WEBSITE_VNET_ROUTE_ALL': '1'
  }
}

resource webSiteConfigVnetInjection 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: subnetId
  }
}


resource webAppHostBinding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = if (webAppWithPrivateLink == true) {
  name: '${webApp.name}/${webApp.name}${webapp_dns_name}'
  properties: {
    siteName: webApp.name
    hostNameType: 'Verified'
  }
}

output webAppID string = webApp.id
