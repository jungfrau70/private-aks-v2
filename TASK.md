## Create User Guide for Scripts

1.  List all the \`.sh\` files in the \`v2/scripts/\` directory.
2.  Read each script and extract a brief description from the comments at the beginning of the file.
3.  Create a user guide in markdown format with a table of contents, script descriptions, and instructions on how to use the scripts.

## Script Descriptions

| Script Name                      | Description                                                                 |
| -------------------------------- | --------------------------------------------------------------------------- |
| \`01\_init.sh\`                  | 1단계: Terraform 초기화                                                       |
| \`02\_check\_resource\_groups.sh\` | 2단계: Azure 리소스 그룹 존재 여부 확인                                         |
| \`03\_1\_check\_hub\_network.sh\`  | Hub 네트워크 리소스 체크 시작                                                   |
| \`03\_2\_check\_spoke\_network.sh\` | Spoke 네트워크 리소스 체크 시작                                                 |
| \`03\_3\_check\_storage\_network.sh\` | Storage 네트워크 리소스 체크 시작                                               |
| \`03\_4\_check\_network\_peerings.sh\` | VNet 피어링 체크 시작                                                          |
| \`03\_check\_network\_resources.sh\` | 네트워크 리소스 체크 시작                                                      |
| \`04\_check\_storage\_resources.sh\` | 4단계: Azure 스토리지 리소스 존재 여부 확인                                         |
| \`05\_check\_acr\_resources.sh\`   | 5단계: Azure Container Registry 리소스 존재 여부 확인                                |
| \`06\_check\_keyvault\_resources.sh\` | KeyVault 리소스 체크 시작                                                        |
| \`07\_check\_aks\_resources.sh\`   | AKS 클러스터 리소스 체크 시작                                                    |
| \`08\_check\_appgw\_resources.sh\`  | 애플리케이션 게이트웨이 리소스 체크 시작                                            |
| \`09\_check\_monitoring\_resources.sh\` | 모니터링 리소스 체크 시작                                                        |
| \`10\_check\_database\_resources.sh\` | 데이터베이스 리소스 체크 시작                                                    |
| \`11\_import\_existing\_resources.sh\` | 기존 리소스를 테라폼 상태로 가져오는 작업을 시작합니다...                                |
| \`20\_deploy\_resource\_groups.sh\` | 리소스 그룹 배포 작업을 시작합니다...                                            |
| \`21\_deploy\_modules.sh\`         | 테라폼 모듈 배포 작업을 시작합니다...                                            |
| \`22\_redeploy\_module.sh\`      | 모듈 재배포 스크립트                                                              |
| \`install\_tools\_jumpbox.sh\`  | Jumpbox VM에 필요한 도구를 설치하는 스크립트                                      |
| \`run\_on\_jumpbox.sh\`        | Jumpbox VM에서 스크립트를 실행하는 스크립트                                          |

## Remaining Steps

1.  Read the remaining scripts in `v2/scripts/` and add their descriptions to the table above.
2.  Create a detailed user guide in markdown format, including:
    *   Introduction
    *   Table of Contents
    *   Detailed description of each script
    *   Instructions on how to use each script
    *   Examples
3.  Add the user guide to the repository.
