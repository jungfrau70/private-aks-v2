FROM nginx:alpine

# 작업 디렉토리 설정
WORKDIR /usr/share/nginx/html

# 기본 nginx 설정 제거
RUN rm -rf ./*

# 애플리케이션 파일 복사
COPY index.html .
COPY style.css .

# 포트 노출
EXPOSE 80

# nginx 실행
CMD ["nginx", "-g", "daemon off;"] 