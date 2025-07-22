#!/bin/bash
set -e

# 변수 설정
RESOURCE_GROUP="<RESOURCE_GROUP_NAME>"
ACR_NAME="<ACR_NAME>"
APP_NAME="<APP_NAME>"
APP_VERSION="1.0.0"
APP_DIR="./app"  # 애플리케이션 소스 코드 디렉토리

# ACR 로그인
echo "ACR 로그인..."
az acr login --name $ACR_NAME

# Dockerfile이 없는 경우 생성
if [ ! -f "$APP_DIR/Dockerfile" ]; then
  echo "Dockerfile 생성..."
  cat > "$APP_DIR/Dockerfile" <<EOF
FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
fi

# Maven 빌드 (Java 애플리케이션인 경우)
if [ -f "$APP_DIR/pom.xml" ]; then
  echo "Maven 빌드 실행..."
  cd $APP_DIR
  ./mvnw clean package -DskipTests
  cd ..
fi

# 이미지 빌드 및 푸시
echo "Docker 이미지 빌드 및 푸시..."
az acr build --registry $ACR_NAME --image $APP_NAME:$APP_VERSION $APP_DIR

echo "이미지가 성공적으로 빌드되어 ACR에 푸시되었습니다: $ACR_NAME.azurecr.io/$APP_NAME:$APP_VERSION" 