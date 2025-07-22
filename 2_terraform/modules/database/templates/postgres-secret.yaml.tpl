apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  POSTGRES_HOST: ${base64encode(postgresql_server_name)}
  POSTGRES_USER: ${base64encode(postgresql_admin_username)}
  POSTGRES_PASSWORD: ${base64encode(postgresql_admin_password)}
  POSTGRES_DB: ${base64encode(postgresql_database_name)}
  POSTGRES_URL: ${base64encode(postgresql_connection_url)} 