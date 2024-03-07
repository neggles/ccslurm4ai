param region string
param principalObjId string
param roleDefinitionIds object
param monitor_tags object

resource azureMonitorWorkspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: 'managedPrometheus'
  location: region
  properties: {}
  tags: monitor_tags
}

resource grafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: substring('grafana-${uniqueString(resourceGroup().id)}', 0, 16)
  location: region
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiKey:'Disabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    deterministicOutboundIP: 'Disabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: azureMonitorWorkspace.id
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

resource role_grafanaWorkspaceReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(grafana.id, roleDefinitionIds.MonitoringDataReader, azureMonitorWorkspace.id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions' , roleDefinitionIds.MonitoringDataReader)
    principalId: grafana.identity.principalId
  }
  scope: azureMonitorWorkspace
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalObjId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionIds.GrafanaAdmin)
    principalId: principalObjId
  }
}

output dataCollectionEndpointResourceId string = azureMonitorWorkspace.properties.defaultIngestionSettings.dataCollectionEndpointResourceId
output dataCollectionRuleResourceId string = azureMonitorWorkspace.properties.defaultIngestionSettings.dataCollectionRuleResourceId
output prometheusQueryEndpoint string = azureMonitorWorkspace.properties.metrics.prometheusQueryEndpoint
output grafanaName string = grafana.name
output monitorWorkspaceId string = azureMonitorWorkspace.id
