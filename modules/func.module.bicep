//https://docs.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code#deploy-on-app-service-plan
param name string
param region string
param tags object
param serverFarmId string
param subnetId string
param numberOfFuncWorkers int // =1
param funcWithPrivateLink bool
var webapp_dns_name = '.azurewebsites.net'
param funcStorageConnectionString string
param funcAppInsInstrumentationKey string
param funcAppSettings array

//az webapp list-runtimes --linux
@allowed([
  'Java|8'
  'Java|11'
  'DOTNETCORE|3.1'
  'NODE|10'
  'NODE|12'
  'NODE|14'
  'PYTHON|3.6'
  'PYTHON|3.7'
  'PYTHON|3.8'
  'PYTHON|3.9'
])
param linuxFuncRuntime string

param runtime string


resource funcApp 'Microsoft.Web/sites@2020-12-01' = {
  name: name
  location: region
  kind: 'functionapp,linux'
  tags: tags
  properties: {
    serverFarmId: serverFarmId
    reserved: true 
    siteConfig: {
      numberOfWorkers: numberOfFuncWorkers
      linuxFxVersion: linuxFuncRuntime
      alwaysOn: true
      http20Enabled: false
      appSettings: concat([
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        // {
        //   name: 'AzureWebJobsDashboard'
        //   value: funcStorageConnectionString
        // }
        {
          name: 'AzureWebJobsStorage'
          value: funcStorageConnectionString
        }
        // these must not be set for funcapp,linux
        // {
        //   name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        //   value: funcStorageConnectionString
        // }
        // {
        //   name: 'WEBSITE_CONTENTSHARE'
        //   value: toLower(replace(replace(name, '-', ''), '_', ''))
        // }        
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: funcAppInsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${funcAppInsInstrumentationKey}'
        }
      ], funcAppSettings)
    }   
  }
}


resource webAppHostBinding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = if (funcWithPrivateLink == true) {
  name: '${funcApp.name}/${funcApp.name}${webapp_dns_name}'
  properties: {
    siteName: funcApp.name
    hostNameType: 'Verified'
  }
}

resource webSiteConfigVnetInjection 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${funcApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: subnetId
  }
}

output funcAppID string = funcApp.id
