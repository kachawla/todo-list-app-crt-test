targetScope = 'resourceGroup'

@description('Radius context object passed into the recipe.')
param context object

@description('Data residency location for the Communication Services and Email Communication Services resources.')
param dataLocation string = 'United States'

var nameSuffix = toLower(take(uniqueString(context.resource.id, resourceGroup().id), 13))

resource emailService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: 'ecs-${nameSuffix}'
  location: 'global'
  properties: {
    dataLocation: dataLocation
  }
}

resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailService
  name: 'AzureManagedDomain'
  location: 'global'
  properties: {
    domainManagement: 'AzureManaged'
    userEngagementTracking: 'Disabled'
  }
}

resource communicationService 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: 'acs-${nameSuffix}'
  location: 'global'
  properties: {
    dataLocation: dataLocation
    linkedDomains: [
      emailDomain.id
    ]
  }
}

output result object = {
  resources: [
    communicationService.id
    emailService.id
    emailDomain.id
  ]
  values: {
    senderAddress: 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    connectionString: communicationService.listKeys().primaryConnectionString
  }
}
