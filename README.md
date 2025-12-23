## CI/CD 流水线设计
项目已配置 GitHub Actions 自动化流水线 (`.github/workflows/ci-cd.yml`)：
- **触发**：代码推送至 `main` 分支时自动运行。
- **阶段**：
    1.  **测试阶段**：准备环境并运行测试。
    2.  **构建阶段**：构建 Docker 应用镜像。

## 蓝绿部署架构设计
项目通过 `docker-compose.yml` 文件定义了标准的蓝绿部署模式：
- **`app_blue` 与 `app_green`**：两个独立且完全相同的应用服务实例，代表“蓝”和“绿”两个环境。
- **`nginx`**：反向代理服务。在实际部署中，通过切换其配置，将用户流量导向“蓝”或“绿”环境，从而实现**零停机更新**和**快速回滚**。
- 此设计将应用版本切换与用户访问完全解耦。

## 如何运行
```bash
# 1. 克隆项目
git clone https://github.com/fengzi13141516/my-cicd-project.git
cd my-cicd-project

# 2. 安装依赖并运行
pip install -r requirements.txt
python app.py
# 访问 http://localhost:5000/health 应返回 “OK”
