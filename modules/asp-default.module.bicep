// default module for Application Service Plan
param name string
param region string
param tags object

// @allowed([
//   'F1'
//   'D1'
//   'B1'
//   'B2'
//   'B3'
//   'S1'
//   'S2'
//   'S3'
//   'P1v2'
//   'P2v2'
//   'P3v2'
//   'P1v3'
//   'P2v3'
//   'P3v3'
// ])
// param skuName string = 'P1v2'

// @allowed([
//   'Free'
//   'Basic'
//   'Standard'
//   'PremiumV2'
//   'PremiumV3'
// ])
// param skuTier string = 'PremiumV2'

@allowed([
  {
    skuName: 'B1'
    skuTier: 'Basic'
  }
  {
    skuName: 'B2'
    skuTier: 'Basic'
  }
  {
    skuName: 'B3'
    skuTier: 'Basic'
  }
  {
    skuName: 'S1'
    skuTier: 'Standard'
  }
  {
    skuName: 'S2'
    skuTier: 'Standard'
  }
  {
    skuName: 'S3'
    skuTier: 'Standard'
  }
  {
    skuName: 'P1v2'
    skuTier: 'PremiumV2'
  }
  {
    skuName: 'P2v2'
    skuTier: 'PremiumV2'
  }
  {
    skuName: 'P3v2'
    skuTier: 'PremiumV2'
  }
  {
    skuName: 'P1v3'
    skuTier: 'PremiumV3'
  }
  {
    skuName: 'P2v3'
    skuTier: 'PremiumV3'
  }
  {
    skuName: 'P3v3'
    skuTier: 'PremiumV3'
  }
])
param skuObject object 

@allowed([
  'app'
  'linux'
])
param OSType string

resource asp 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: name
  location: region
  tags: tags
  kind: OSType
  sku: {
    name: skuObject.skuName
    tier: skuObject.skuTier
  }
  properties: {
    //reserved is true if app service plan is Linux
    reserved: OSType == 'linux' 
  }
}


output aspName string = asp.name
output aspOS string = asp.kind
output serverFarmId string = asp.id
