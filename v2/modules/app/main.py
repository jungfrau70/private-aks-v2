import json
import os
import dash
import networkx as nx
import plotly.graph_objects as go
from dash import dcc, html, Input, Output
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from werkzeug.utils import secure_filename

# 🔹 저장 디렉토리 설정
UPLOAD_FOLDER = "tfstate_files"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 🔹 Dash 앱 설정
app = dash.Dash(__name__)
app.config.suppress_callback_exceptions = True

# 🔹 Azure 인증
credential = DefaultAzureCredential()
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
resource_client = ResourceManagementClient(credential, subscription_id)

# 🔹 Terraform `tfstate` 파일 목록 가져오기
def get_tfstate_files():
    return [f for f in os.listdir(UPLOAD_FOLDER) if f.endswith(".tfstate")]

# 🔹 Terraform `tfstate` 파일에서 리소스 읽기
def load_tfstate(file_path):
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
        return [(res["name"], res["type"]) for res in data.get("resources", [])]
    except Exception as e:
        return []

# 🔹 Azure API에서 리소스 상태 조회
def fetch_azure_resources():
    resources = []
    for rg in resource_client.resource_groups.list():
        for res in resource_client.resources.list_by_resource_group(rg.name):
            env = res.tags.get("environment", "unknown") if res.tags else "unknown"
            resources.append((res.name, res.type, rg.name, env))
    return resources

# 🔹 Dash UI 구성
app.layout = html.Div([
    html.H1("Terraform tfstate 기반 Azure 리소스 모니터링"),
    
    # 🔹 파일 업로드
    dcc.Upload(
        id="upload-tfstate",
        children=html.Button("Upload tfstate"),
        multiple=False
    ),
    
    # 🔹 `tfstate` 선택
    dcc.Dropdown(
        id="tfstate-selector",
        options=[{"label": f, "value": f} for f in get_tfstate_files()],
        placeholder="Select tfstate file...",
    ),
    
    # 🔹 환경 필터
    dcc.Dropdown(
        id="env-filter",
        options=[{"label": env, "value": env} for env in ["prod", "staging", "dev"]],
        multi=True,
        placeholder="Filter by environment..."
    ),

    dcc.Graph(id="azure-graph"),  # 🔹 네트워크 그래프
    dcc.Interval(id="interval-component", interval=10000, n_intervals=0),  # 🔄 10초마다 업데이트
])

# 🔹 tfstate 파일 업로드 처리
@app.callback(
    Output("tfstate-selector", "options"),
    Input("upload-tfstate", "contents"),
    Input("upload-tfstate", "filename")
)
def upload_file(contents, filename):
    if contents and filename:
        file_path = os.path.join(UPLOAD_FOLDER, secure_filename(filename))
        with open(file_path, "wb") as f:
            f.write(contents.encode("utf-8"))  # 저장
    return [{"label": f, "value": f} for f in get_tfstate_files()]

# 🔹 그래프 업데이트
@app.callback(
    Output("azure-graph", "figure"),
    [Input("tfstate-selector", "value"), Input("env-filter", "value"), Input("interval-component", "n_intervals")]
)
def update_graph(selected_tfstate, selected_env, n_intervals):
    if not selected_tfstate:
        return go.Figure()

    # 🔹 선택한 tfstate 파일 로드
    terraform_resources = load_tfstate(os.path.join(UPLOAD_FOLDER, selected_tfstate))
    azure_resources = fetch_azure_resources()

    # 🔹 NetworkX 그래프 생성
    G = nx.Graph()
    for name, r_type, rg, env in azure_resources:
        if selected_env and env not in selected_env:
            continue
        G.add_node(name, type=r_type, group=rg, color="red" if env == "prod" else "green")

    pos = nx.spring_layout(G)
    node_trace = go.Scatter(
        x=[pos[n][0] for n in G.nodes],
        y=[pos[n][1] for n in G.nodes],
        text=[f"{n} ({G.nodes[n]['type']}) - {G.nodes[n]['group']}" for n in G.nodes],
        mode="markers+text",
        marker=dict(size=15, color=[G.nodes[n]["color"] for n in G.nodes]),
    )

    return go.Figure(data=[node_trace])

# 🔹 서버 실행
if __name__ == "__main__":
    app.run_server(debug=True)
