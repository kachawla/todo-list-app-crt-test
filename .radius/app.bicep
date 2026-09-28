extension radius

param environment string

@secure()
param mysqlPassword string

@description('Password/token for the OCI registry the containerImages recipe pushes to (a GitHub token with write:packages for ghcr.io).')
@secure()
param registryPassword string

@description('Username for the OCI registry the containerImages recipe pushes to (the GitHub actor for ghcr.io).')
@secure()
param registryUsername string

resource todoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'todo-list-app-crt-test'
  properties: {
    environment: environment
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'src/persistence/mysql.js#L31'
    database: 'todos'
    password: mysqlPassword
    tls: 'optional'
    username: 'myadmin'
    version: '8.0'
  }
}

resource mysqlClientCredentials 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'mysql-client-credentials'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'src/persistence/mysql.js#L10'
    data: {
      password: {
        value: mysqlPassword
      }
    }
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: '.radius/app.bicep#L51'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource todoImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'todo-list-app-crt-test-image'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'Dockerfile'
    build: {
      platforms: [
        'linux/amd64'
      ]
      source: 'git::https://github.com/kachawla/todo-list-app-crt-test.git?ref=5a6fbf5caf982f1d928fe6c1c32aa74f1e95e063'
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource todoContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-list-app-crt-test'
  properties: {
    environment: environment
    application: todoApp.id
    codeReference: 'src/index.js#L18'
    containers: {
      todo: {
        image: todoImage.properties.imageReference
        env: {
          MYSQL_DB: {
            value: 'todos'
          }
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                key: 'password'
                secretName: mysqlClientCredentials.name
              }
            }
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}
