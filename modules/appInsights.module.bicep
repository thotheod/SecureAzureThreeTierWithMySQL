param name string
param region string
param tags object

var workspaceName = 'law-${name}'

resource AppIsightsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: region
  name: workspaceName
  tags: tags
  properties: {
    retentionInDays: 90
    sku:{
      name:'PerGB2018'
    }
  }
}

resource appIns 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: name
  location: region
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    WorkspaceResourceId: AppIsightsWorkspace.id
  }
}


output id string = appIns.id
output instrumentationKey string = appIns.properties.InstrumentationKey
output workspaceId string = AppIsightsWorkspace.id
