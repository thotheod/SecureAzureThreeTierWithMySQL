// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS General
param suffix string = 'secureThreeTier'

// PARAMS Vnet
param vnetAddressSpace string = '172.16.0.0/22'
param resourceTags object
param region string = 'northeurope'
param snetDefault object = {
  name: 'snet-apps'
  subnetPrefix: '172.16.0.0/24'
}  
param snetWAF object = {
  ///26 delegates subnet for App Service VNet Integration. 64 addresses give you up to 29 units scaling  https://docs.microsoft.com/en-us/azure/app-service/web-sites-integrate-with-vnet
  name: 'snet-AppGW'
  subnetPrefix: '172.16.1.0/26'
}
param snetWS object = {
  name: 'snet-WebServers'
  subnetPrefix: '172.16.1.64/26'
}
param snetAdmin object = {
  name: 'snet-Admin'
  subnetPrefix: '172.16.1.128/26'
}
param snetBastion object = {
  name: 'AzureBastionSubnet'
  subnetPrefix: '172.16.1.192/27'
}


// PARAMS App Service Plan
param skuAspObject object
param AspOsType string = 'linux'
param privateDNSZoneNameForWebApp string = 'privatelink.azurewebsites.net'
param serviceLinkGroupIdsForWebApp array = [
  'sites'
]
var webAppWithPrivateLink = contains(skuAspObject.skuTier, 'Premium')
var isWebAppVnetIntegrated = contains(skuAspObject.skuTier, 'Premium') || contains(skuAspObject.skuTier, 'Standard')

// PARAMS MySQL Server
param dbAdminLogin string
param dbAdminPassword string 
param mySqlSkuObject object

param mySQLDBName string
param mySQLBehindPrivateEndpoint bool = !contains(mySqlSkuObject.SkuTier, 'Basic')
param privateDNSZoneNameForMySQL string = 'privatelink.mysql.database.azure.com'
param serviceLinkGroupIdsForMySQL array = [
  'mysqlServer'
]

//PARAMS ServiceBus
param sbSku string 
param sbCapacity int = 1
param sbCreateQueue bool = true
param sbCreateTopic bool = !contains(sbSku, 'Basic')
param sbBehindPrivateEndpoint bool = contains(sbSku, 'Premium')
param privateDNSZoneNameForSB string = 'privatelink.servicebus.windows.net'
param serviceLinkGroupIdsForSB array = [
  'namespace'
]

// PARAMS Function
param linuxFunctionRuntime string = 'Java|11'
param privateDNSZoneNameForFuncApp string = 'privatelink.azurewebsites.net'
param serviceLinkGroupIdsForFuncApp array = [
  'sites'
]
param funcRuntime string = 'java'

//PARAMS Func storage
param funcStorKind string = 'StorageV2'
param funcStorSku object = {
  name: 'Standard_LRS'
  tier: 'Standard'
}

//PARAMS App GW
param appGwaySKU string = 'Standard_v2'
param aGwMinCapacity int = 1
param aGwMaxCapacity int = 10
param aGwBackendIPAddresses array = []
param appGateWayName string = 'agw-${suffix}'

//PARAM jumpHostVM
param vmName string = 'vmWinJumpHost'
@secure()
param vmAdminUserName string
@secure()
param vmAdminPassword string
param windowsOSVersion string = '2019-Datacenter'
param vmSize string = 'Standard_D2_v3'

// VARS
var env = resourceTags.Environment
var vnetName = 'vnet-${env}-${suffix}'
var aspName = 'plan-${env}-${suffix}'
var webAppName = 'app-${env}-${suffix}'
var funcAppName = 'func-${env}-${suffix}'
var peFuncName = 'pe-${env}-${funcAppName}' 
var peWebAppName = 'pe-${env}-${webAppName}'
var peMySQLName = 'pe-${env}-${mySQLDBName}'
var sbNamespaceName = 'sb-${env}-${suffix}'
var peSBName = 'pe-${sbNamespaceName}'
var sbQueueName = 'sbq-${sbNamespaceName}'
var sbTopicName = 'sbt-${sbNamespaceName}'
var appInsightsName = 'appi-${env}-${suffix}'
var funcStorageName = 'st${env}${suffix}'
var pipAppGWName = 'pip-${env}-${appGateWayName}'

// CREATE RESOURCES
module vnet 'modules/vnet.module.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    region: resourceGroup().location    
    snetDefault: snetDefault
    snetWAF: snetWAF
    snetWS: snetWS   
    snetAdmin: snetAdmin
    snetBastion: snetBastion    
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags  
  }
}

module asp 'modules/asp-default.module.bicep' = {
  name: 'AppServicePlanDeployment-${aspName}'
  params: {
    name: aspName
    region: resourceGroup().location
    tags: resourceTags
    skuObject: skuAspObject
    OSType: AspOsType
  }
}

module webApp 'modules/webapp.module.bicep' = {
  name: 'WebAppDeployment-${webAppName}'
  params: {
    name: webAppName
    region: resourceGroup().location
    tags: resourceTags
    serverFarmId: asp.outputs.serverFarmId
    subnetId: isWebAppVnetIntegrated ? vnet.outputs.snetWSID : ''
    webAppWithPrivateLink: webAppWithPrivateLink
  }
}

module azureSitesDNSZone 'modules/PrivateDNSZones.module.bicep' = if (webAppWithPrivateLink) {
  name: 'azureSitesDNSZoneDeployment'
  params: {
    privateDNSZoneName: privateDNSZoneNameForWebApp
    vnetID: vnet.outputs.vnetID
  }
}


module webAppPrivateLink 'modules/PE.module.bicep' = if (webAppWithPrivateLink) {
  name: 'PEWebAppDeployment-${peWebAppName}'
  params: {
    PrivEndpointName: peWebAppName
    region: resourceGroup().location
    tags: resourceTags
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: webApp.outputs.webAppID
     serviceLinkGroupIds: serviceLinkGroupIdsForWebApp
     privateDnsZonesId:  azureSitesDNSZone.outputs.privateDnsZonesId 
  }
}

module funcApp 'modules/func.module.bicep' = {
  name: 'FuncDeployment-${funcAppName}'
  params: {
    name: funcAppName
    region: resourceGroup().location
    tags: resourceTags
    subnetId: isWebAppVnetIntegrated ? vnet.outputs.snetWSID : ''
    serverFarmId: asp.outputs.serverFarmId
    funcAppSettings: []
    funcAppInsInstrumentationKey: appInsights.outputs.instrumentationKey
    funcStorageConnectionString: funcStorage.outputs.connectionString
    linuxFuncRuntime: linuxFunctionRuntime
    numberOfFuncWorkers: 1
    funcWithPrivateLink: webAppWithPrivateLink
    runtime: funcRuntime
  }
}

module funcPrivateLink 'modules/PE.module.bicep' = if (webAppWithPrivateLink) {
  name: 'PEFuncDeployment-${peFuncName}'
  params: {
    PrivEndpointName: peFuncName
    region: resourceGroup().location
    tags: resourceTags    
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: funcApp.outputs.funcAppID    
    serviceLinkGroupIds: serviceLinkGroupIdsForFuncApp
    privateDnsZonesId: azureSitesDNSZone.outputs.privateDnsZonesId
  }
}


module dbMySQL 'modules/mySQLDB.module.bicep' = {
  name: 'MySQLDeployment-${mySQLDBName}'
  params: {
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
    dbSkuCapacity: mySqlSkuObject.Capacity
    dbSkuFamily: mySqlSkuObject.SkuFamily
    dbSkuName: mySqlSkuObject.SkuName
    dbSkuSizeInMB: mySqlSkuObject.DBSize
    dbSkuTier: mySqlSkuObject.SkuTier
    mySQLBehindPrivateEndpoint: mySQLBehindPrivateEndpoint
    mySQLVersion: mySqlSkuObject.mySQLVersion
    name: mySQLDBName
    region: resourceGroup().location
    tags: resourceTags
  }
}

module mySQLPrivateLink 'modules/PE.module.bicep' = if (mySQLBehindPrivateEndpoint) {
  name: 'PE-MySQLDeployment-${peMySQLName}'
  params: {
    PrivEndpointName: peMySQLName
    region: resourceGroup().location
    tags: resourceTags
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: dbMySQL.outputs.mySQLDBId
    serviceLinkGroupIds: serviceLinkGroupIdsForMySQL
    privateDnsZonesId: mySqlDNSZone.outputs.privateDnsZonesId
  }
}

module mySqlDNSZone 'modules/PrivateDNSZones.module.bicep' = if (mySQLBehindPrivateEndpoint) {
  name: 'MySqlDNSZoneDeployment'
  params: {
    privateDNSZoneName: privateDNSZoneNameForMySQL
    vnetID: vnet.outputs.vnetID
  }
}

module sb 'modules/SB.module.bicep' = {
  name: 'SBDeployment-${sbNamespaceName}'
  params: {
    msgUnits: sbCapacity
    name: sbNamespaceName
    region: resourceGroup().location
    sbCreateQueue: sbCreateQueue
    sbCreateTopic: sbCreateTopic
    sbQueueName: sbCreateQueue ? sbQueueName : ''
    sbTopicName: sbTopicName 
    sku: sbSku
    tags: resourceTags
  }
}

module sbPrivateLink 'modules/PE.module.bicep' = if (sbBehindPrivateEndpoint) {
  name: 'PESBDeployment-${peSBName}'
  params: {
    PrivEndpointName: peSBName
    region: resourceGroup().location
    tags: resourceTags
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: sb.outputs.sbID
    serviceLinkGroupIds: serviceLinkGroupIdsForSB
    privateDnsZonesId: sbDNSZone.outputs.privateDnsZonesId
  }
}

module sbDNSZone 'modules/PrivateDNSZones.module.bicep' = if (sbBehindPrivateEndpoint) {
  name: 'sbDNSZoneDeployment'
  params: {
    privateDNSZoneName: privateDNSZoneNameForSB
    vnetID: vnet.outputs.vnetID
  }
}

module appInsights 'modules/appInsights.module.bicep' = {
  name: 'appInsightsDeployment-${appInsightsName}'
  params: {
    name: appInsightsName
    region: resourceGroup().location
    tags: resourceTags
  }
}

module funcStorage 'modules/storage.module.bicep' = {
  name: 'funcStorageDeployment-${funcStorageName}'
  params: {
    name: funcStorageName
    region: resourceGroup().location
    tags: resourceTags
    kind: funcStorKind
    sku: funcStorSku
  }
}

module pipAppGateWay 'modules/pipStaticStandard.module.bicep' = {
  name: 'pipAppGateWayDeployment'
  params:{
    name: pipAppGWName
    region: resourceGroup().location
    tags: resourceTags
  }
}

module appGW 'modules/WAF.module.bicep' = {
  name: 'appGWDeployment-${appGateWayName}'
  params:{
    name: appGateWayName
    region: resourceGroup().location
    tags: resourceTags
    appGwaySKU: appGwaySKU
    backendIPAddresses: aGwBackendIPAddresses
    minCapacity: aGwMinCapacity
    maxCapacity: aGwMaxCapacity
    pipID: pipAppGateWay.outputs.pipID
    subnetID: vnet.outputs.snetWAFID
  }
}

module vmJumpBox 'modules/jumpBox.module.bicep' = if (env == 'Prod') {
  name: 'VMDeployment-${vmName}'
  params: {
    name: vmName
    location: resourceGroup().location
    tags: resourceTags
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPassword
    dnsLabelPrefix: 'vmwin'
    subnetId: vnet.outputs.snetAdminID
    vmSize: vmSize
    windowsOSVersion: windowsOSVersion
  }
}
