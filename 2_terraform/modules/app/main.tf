# GitHub 리포지토리 생성 (선택 사항)
resource "github_repository" "app_repo" {
  count       = var.create_github_repo ? 1 : 0
  name        = var.github_repo_name
  description = var.github_repo_description
  visibility  = var.github_repo_visibility
  
  auto_init = true
  
  template {
    owner      = var.github_template_owner
    repository = var.github_template_repo
  }
}

# GitHub Actions 시크릿 설정 (선택 사항)
resource "github_actions_secret" "azure_credentials" {
  count           = var.create_github_repo ? 1 : 0
  repository      = github_repository.app_repo[0].name
  secret_name     = "AZURE_CREDENTIALS"
  plaintext_value = var.azure_credentials_json
}

resource "github_actions_secret" "acr_login_server" {
  count           = var.create_github_repo ? 1 : 0
  repository      = github_repository.app_repo[0].name
  secret_name     = "ACR_LOGIN_SERVER"
  plaintext_value = var.acr_login_server
}

resource "github_actions_secret" "resource_group" {
  count           = var.create_github_repo ? 1 : 0
  repository      = github_repository.app_repo[0].name
  secret_name     = "RESOURCE_GROUP"
  plaintext_value = var.resource_group_name
}

resource "github_actions_secret" "aks_cluster_name" {
  count           = var.create_github_repo ? 1 : 0
  repository      = github_repository.app_repo[0].name
  secret_name     = "AKS_CLUSTER_NAME"
  plaintext_value = var.aks_cluster_name
}

# 애플리케이션 배포를 위한 Kubernetes 매니페스트 생성
resource "local_file" "app_deployment" {
  content = templatefile("${path.module}/${var.app_template_path}/app-deployment.yaml.tpl", {
    app_name          = var.app_name
    namespace_name    = var.app_namespace
    app_image         = "${var.acr_login_server}/${var.app_image_name}:${var.app_image_tag}"
    app_replicas      = var.app_replicas
    app_port          = var.app_port
    app_cpu_request   = var.app_cpu_request
    app_memory_request = var.app_memory_request
    app_cpu_limit     = var.app_cpu_limit
    app_memory_limit  = var.app_memory_limit
  })
  filename = "${path.module}/${var.app_output_path}/app-deployment.yaml"
}

resource "local_file" "app_service" {
  content = templatefile("${path.module}/${var.app_template_path}/app-service.yaml.tpl", {
    app_name = var.app_name
    app_port = var.app_port
  })
  filename = "${path.module}/${var.app_output_path}/app-service.yaml"
}

resource "local_file" "app_ingress" {
  content = templatefile("${path.module}/${var.app_template_path}/app-ingress.yaml.tpl", {
    app_name      = var.app_name
    namespace_name = var.app_namespace
    app_host      = var.app_host
    app_path      = var.app_path
    app_port      = var.app_port
    use_agic      = var.use_agic
    enable_tls    = var.enable_tls
    ingress_class = var.ingress_class
    tls_secret_name = var.tls_secret_name
  })
  filename = "${path.module}/${var.app_output_path}/app-ingress.yaml"
}

# 애플리케이션 빌드 및 배포 스크립트 생성
resource "local_file" "app_build_script" {
  content = templatefile("${path.module}/${var.app_template_path}/app-build.sh.tpl", {
    acr_login_server = var.acr_login_server
    app_image_name   = var.app_image_name
    app_image_tag    = var.app_image_tag
    app_source_dir   = var.app_source_dir
  })
  filename = "${path.module}/${var.app_output_path}/app-build.sh"
}

resource "local_file" "app_deploy_script" {
  content = templatefile("${path.module}/${var.app_template_path}/app-deploy.sh.tpl", {
    resource_group_name = var.resource_group_name
    aks_cluster_name    = var.aks_cluster_name
    app_name            = var.app_name
    app_namespace       = var.app_namespace
  })
  filename = "${path.module}/${var.app_output_path}/app-deploy.sh"
}

# GitHub Actions 워크플로우 파일 생성
resource "local_file" "github_workflow" {
  content = templatefile("${path.module}/${var.app_template_path}/github-workflow.yml.tpl", {
    acr_login_server = var.acr_login_server
    app_image_name   = var.app_image_name
    app_source_dir   = var.app_source_dir
    namespace_name   = var.app_namespace
  })
  filename = "${path.module}/${var.app_output_path}/github-workflow.yml"
}

# 매니페스트 파일 생성 - 실제 배포는 하지 않음
resource "local_file" "kubernetes_namespace" {
  content = templatefile("${path.module}/${var.app_template_path}/app-namespace.yaml.tpl", {
    namespace_name = "app"
  })
  filename = "${path.module}/${var.app_output_path}/namespace.yaml"
}

resource "local_file" "kubernetes_deployment" {
  content = templatefile("${path.module}/${var.app_template_path}/app-deployment.yaml.tpl", {
    app_name = var.app_name
    namespace_name = "app"
    app_image = "${var.acr_login_server}/${var.app_image_name}:${var.app_image_tag}"
    app_replicas = var.replicas
    app_port = var.port
    app_cpu_request = var.cpu_request
    app_memory_request = var.memory_request
    app_cpu_limit = var.cpu_limit
    app_memory_limit = var.memory_limit
  })
  filename = "${path.module}/${var.app_output_path}/deployment.yaml"
}

resource "local_file" "kubernetes_service" {
  content = templatefile("${path.module}/${var.app_template_path}/app-service.yaml.tpl", {
    app_name = var.app_name
    namespace_name = "app"
    app_port = var.port
  })
  filename = "${path.module}/${var.app_output_path}/service.yaml"
}

resource "local_file" "kubernetes_ingress" {
  content = templatefile("${path.module}/${var.app_template_path}/app-ingress.yaml.tpl", {
    app_name = var.app_name
    namespace_name = "app"
    app_host = var.app_host
    app_port = var.port
    app_path = var.app_path
    use_agic = var.ingress_class == "azure/application-gateway" ? true : false
    ingress_class = var.ingress_class
    enable_tls = var.enable_tls
    tls_secret_name = var.tls_secret_name
  })
  filename = "${path.module}/${var.app_output_path}/ingress.yaml"
} 