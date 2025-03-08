# Jumpbox VM 도구 설치 안내

이 디렉토리에는 Jumpbox VM에 필요한 도구를 설치하는 스크립트가 포함되어 있습니다.

## 설치 방법

### 1. 스크립트 파일 전송

Jumpbox VM에 스크립트 파일을 전송합니다. 다음 방법 중 하나를 선택하세요:

#### SCP를 사용하여 전송

```bash
scp v2/scripts/install_tools_jumpbox.sh azureuser@<JUMPBOX_IP>:/home/azureuser/
```

#### Azure CLI를 사용하여 전송

```bash
az vm run-command invoke \
  --resource-group <RESOURCE_GROUP> \
  --name <JUMPBOX_VM_NAME> \
  --command-id RunShellScript \
  --scripts "curl -o /home/azureuser/install_tools_jumpbox.sh https://raw.githubusercontent.com/yourusername/yourrepo/main/v2/scripts/install_tools_jumpbox.sh"
```

### 2. 스크립트 실행

Jumpbox VM에 SSH로 접속한 후 다음 명령어를 실행합니다:

```bash
# 실행 권한 부여
chmod +x /home/azureuser/install_tools_jumpbox.sh

# 스크립트 실행 (sudo 권한 필요)
sudo bash /home/azureuser/install_tools_jumpbox.sh
```

### 3. 설치 확인

설치가 완료된 후 다음 명령어로 도구가 제대로 설치되었는지 확인합니다:

```bash
# Azure CLI 확인
az --version

# Docker 확인
docker --version

# kubectl 확인
kubectl version --client
```

### 4. 문제 해결

설치 중 문제가 발생한 경우 로그 파일을 확인하세요:

```bash
cat /var/log/jumpbox_tools_install.log
```

Docker 그룹 권한이 적용되지 않은 경우 다음 명령어를 실행하거나 VM을 재부팅하세요:

```bash
# 현재 세션에 그룹 권한 적용
newgrp docker

# 또는 VM 재부팅
sudo reboot
```

## 설치되는 도구 목록

- Azure CLI
- Docker
- kubectl
- Helm
- kubectx 및 kubens
- k9s
- 기타 유틸리티 (jq, git, curl 등)

## 추가 스크립트

설치 과정에서 다음 유틸리티 스크립트가 생성됩니다:

- `/home/azureuser/get_aks_credentials.sh`: AKS 클러스터 자격 증명 가져오기
- `/home/azureuser/mount_fileshare.sh`: Azure 파일 공유 마운트 