extension radius

resource pack 'Radius.Core/recipePacks@2025-08-01-preview' = {
  name: 'todo-list-app-crt-test-custom'
  properties: {
    recipes: {
      'Radius.Resources/emailCommunicationServices': {
        kind: 'bicep'
        source: 'ghcr.io/kachawla/todo-list-app-crt-test/email-communication-services:bd18797'
      }
    }
  }
}
