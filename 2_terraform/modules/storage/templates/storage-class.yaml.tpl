apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile
provisioner: kubernetes.io/azure-file
parameters:
  storageAccount: ${storage_account_name}
  secretName: azure-storage-secret
  shareName: ${file_share_name}
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: v1
kind: Secret
metadata:
  name: azure-storage-secret
type: Opaque
data:
  azurestorageaccountname: ${base64encode(storage_account_name)}
  azurestorageaccountkey: ${base64encode(storage_account_key)}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: azurefile-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: azurefile
  azureFile:
    secretName: azure-storage-secret
    shareName: ${file_share_name}
    readOnly: false
  mountOptions:
    - dir_mode=0777
    - file_mode=0777
    - uid=1000
    - gid=1000
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azurefile-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile
  resources:
    requests:
      storage: 5Gi 