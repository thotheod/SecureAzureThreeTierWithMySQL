param name string
param region string
param tags object
param sbBehindPrivateEndpoint bool

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string

@allowed([
  1
  2
  4
])
param msgUnits int

param sbCreateQueue bool 
param sbQueueName string = ''
param sbCreateTopic bool
param sbTopicName string = ''
param vnetSubnetID string = ''

resource sb 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: name
  location: region
  tags: tags
  sku: {
    name: sku
    tier: sku
    capacity: msgUnits
  }
  properties: {
    zoneRedundant: sku == 'Premium'
  }
}

//TODO: Not sure if this is needed and if is correct
// resource sbRulesets 'Microsoft.ServiceBus/namespaces/virtualnetworkrules@2018-01-01-preview' = if (sbBehindPrivateEndpoint) {
//   name: '${sb.name}/default'
//   properties: {
//     virtualNetworkSubnetId: vnetSubnetID
//   }
// }

resource sbQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = if (sbCreateQueue) {
  name: '${sb.name}/${sbQueueName}'
  properties: {
    lockDuration: 'PT30S'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: true
    requiresSession: true
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource sbTopic 'Microsoft.ServiceBus/namespaces/topics@2018-01-01-preview' = if (sbCreateTopic) {
  name:  '${sb.name}/${sbTopicName}'
  properties: {
    defaultMessageTimeToLive: 'P14D'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: true
    status: 'Active'
    autoDeleteOnIdle: 'P14D'
    enablePartitioning: false
    enableExpress: false   
    supportOrdering: true
  }
}

output sbID string = sb.id
