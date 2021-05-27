param name string
param region string
param tags object

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


param sbQueueProps object = {
  lockDuration: 'PT30S'
  maxSizeInMegabytes: 1024
  deadLetteringOnMessageExpiration: true
  maxDeliveryCount: 10
  enablePartitioning: false
}

param sbQueueNonBasicProps object = {    
  requiresDuplicateDetection:  true
  requiresSession: true
  defaultMessageTimeToLive: 'P14D'
  duplicateDetectionHistoryTimeWindow: 'PT10M'
  autoDeleteOnIdle:  'P10675199DT2H48M5.4775807S'
  enableExpress: false
}


//https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-resource-manager-exceptions
resource sbQueue 'Microsoft.ServiceBus/namespaces/queues@2018-01-01-preview' = if (sbCreateQueue) {
  name: '${sb.name}/${sbQueueName}'
  properties: contains(sku, 'Basic') ? sbQueueProps : union(sbQueueProps, sbQueueNonBasicProps)
}

resource sbTopic 'Microsoft.ServiceBus/namespaces/topics@2018-01-01-preview' = if (sbCreateTopic) {
  name: '${sb.name}/${sbTopicName}'
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
