param name string
param region string
param tags object
param dbAdminLogin string
param mySQLBehindPrivateEndpoint bool

@secure()
@minLength(8)
@maxLength(128)
param dbAdminPassword string 

@allowed([
  1
  2
  4
  8
  16
  32
])
param dbSkuCapacity int

@allowed([
  'B_Gen5_1'
  'B_Gen5_2'
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_8'
  'GP_Gen5_16'
  'GP_Gen5_32'
  'MO_Gen5_2'
  'MO_Gen5_4'
  'MO_Gen5_8'
  'MO_Gen5_16'
  'MO_Gen5_32'
])
param dbSkuName string

@allowed([
  51200
  102400
])
param dbSkuSizeInMB int

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param dbSkuTier string

param dbSkuFamily string

@allowed([
  '5.6'
  '5.7'
])
param mySQLVersion string


resource dbServer 'Microsoft.DBForMySQL/servers@2017-12-01' = {
  name: name
  location: region
  tags: tags
  sku: {
    name: dbSkuName
    tier: dbSkuTier
    capacity: dbSkuCapacity
    size: string(dbSkuSizeInMB)
    family: dbSkuFamily
  }
  properties: {
    createMode: 'Default'
    version: mySQLVersion
    administratorLogin: dbAdminLogin
    administratorLoginPassword: dbAdminPassword
    storageProfile: {
      storageMB: dbSkuSizeInMB
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
    publicNetworkAccess: mySQLBehindPrivateEndpoint ? 'Disabled' : 'Enabled'
  }
}

output mySQLDBId string = dbServer.id
