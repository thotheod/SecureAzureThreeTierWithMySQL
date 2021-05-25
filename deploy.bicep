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
param skuAspObject object = {
  skuName: 'P1v3'
  skuTier: 'PremiumV3'
}
param AspOsType string = 'linux'
param webAppWithPrivateLink bool = true //needs the web app be behind private link?
param privateDNSZoneNameForWebApp string = 'privatelink.azurewebsites.net'
param serviceLinkGroupIdsForWebApp array = [
  'sites'
]

// PARAMS MySQL Server
param dbAdminLogin string
param dbAdminPassword string 
param dbSkuCapacity int = 2
param dbSkuName string = 'GP_Gen5_2'
param dbSkuSizeInMB int = 51200
param dbSkuTier string = 'GeneralPurpose'
param dbSkuFamily string = 'Gen5'
param mySQLVersion string = '5.7'
param mySQLDBName string
param mySQLBehindPrivateEndpoint bool = true
param privateDNSZoneNameForMySQL string = 'privatelink.mysql.database.azure.com'
param serviceLinkGroupIdsForMySQL array = [
  'mysqlServer'
]

//PARAMS ServiceBus
param sbName string
param sbSku string = 'Premium'
param sbCapacity int = 1
param sbCreateQueue bool = true
param sbCreateTopic bool = true
param sbBehindPrivateEndpoint bool = true
param privateDNSZoneNameForSB string = 'privatelink.servicebus.windows.net'
param serviceLinkGroupIdsForSB array = [
  'namespace'
]
// param sbRuleSetVnetSubnetID string

// VARS
var vnetName = 'vnet-${suffix}'
var aspName = 'plan-${suffix}'
var webAppName = 'app-${suffix}'
var peWebAppName = 'pe-${webAppName}'
var peMySQLName = 'pe-${mySQLDBName}'
var sbNamespaceName = 'sb-${sbName}'
var peSBName = 'pe-${sbNamespaceName}'
var sbQueueName = 'sbq-${sbName}'
var sbTopicName = 'sbt-${sbName}'

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
    subnetId: vnet.outputs.snetWSID
    webAppWithPrivateLink: webAppWithPrivateLink
  }
}

module webAppPrivateLink 'modules/PE.module.bicep' = if (webAppWithPrivateLink) {
  name: 'PEWebAppDeployment-${peWebAppName}'
  params: {
    PrivEndpointName: peWebAppName
    region: resourceGroup().location
    tags: resourceTags
    vnetID: vnet.outputs.vnetID
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: webApp.outputs.webAppID
    privateDNSZoneName: privateDNSZoneNameForWebApp
    serviceLinkGroupIds: serviceLinkGroupIdsForWebApp
  }
}

module dbMySQL 'modules/mySQLDB.module.bicep' = {
  name: 'MySQLDeployment-${mySQLDBName}'
  params: {
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
    dbSkuCapacity: dbSkuCapacity
    dbSkuFamily: dbSkuFamily
    dbSkuName: dbSkuName
    dbSkuSizeInMB: dbSkuSizeInMB
    dbSkuTier: dbSkuTier
    mySQLBehindPrivateEndpoint: mySQLBehindPrivateEndpoint
    mySQLVersion: mySQLVersion
    name: mySQLDBName
    region: resourceGroup().location
    tags: resourceTags
  }
}

module mySQLPrivateLink 'modules/PE.module.bicep' = if (mySQLBehindPrivateEndpoint) {
  name: 'PEWebAppDeployment-${peMySQLName}'
  params: {
    PrivEndpointName: peMySQLName
    region: resourceGroup().location
    tags: resourceTags
    vnetID: vnet.outputs.vnetID
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: dbMySQL.outputs.mySQLDBId
    privateDNSZoneName: privateDNSZoneNameForMySQL
    serviceLinkGroupIds: serviceLinkGroupIdsForMySQL
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
    sbTopicName: sbCreateTopic ? sbTopicName : ''
    sku: sbSku
    tags: resourceTags
    vnetSubnetID: vnet.outputs.snetWSID
    sbBehindPrivateEndpoint: sbBehindPrivateEndpoint
  }
}

module sbPrivateLink 'modules/PE.module.bicep' = if (sbBehindPrivateEndpoint) {
  name: 'PEWebAppDeployment-${peSBName}'
  params: {
    PrivEndpointName: peSBName
    region: resourceGroup().location
    tags: resourceTags
    vnetID: vnet.outputs.vnetID
    snetID: vnet.outputs.snetDefaultID
    pLinkServiceID: sb.outputs.sbID
    privateDNSZoneName: privateDNSZoneNameForSB
    serviceLinkGroupIds: serviceLinkGroupIdsForSB
  }
}
