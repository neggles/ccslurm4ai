param region string
param config object
param subnetIds object

resource prometheusNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'prometheusNSG'
  location: region
}

resource prometheusNIC 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'prometheusNIC'
  location: region
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetIds[config.subnetName]
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: prometheusNSG.id
    }
  }
}

resource prometheus 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'prometheus'
  location: region
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v4'
    }
    storageProfile: {
      osDisk: {
        name: 'prometheusOSDisk'
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: config.vmImage
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: prometheusNIC.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'prometheus'
      adminUsername: config.adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${config.adminUsername}/.ssh/authorized_keys'
              keyData: config.sshPublicKey
            }
          ]
        }
      }
    }
  }
}

output id string = prometheus.id
output privateIp string = prometheusNIC.properties.ipConfigurations[0].properties.privateIPAddress
output adminUsername string = prometheus.properties.osProfile.adminUsername
