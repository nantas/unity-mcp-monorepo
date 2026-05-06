# AnkleBreaker Unity MCP 安装工作流

本文档描述如何将 Unity MCP（plugin + server）安装到 Unity 项目。

> **占位符约定**
> - `<MONOREPO_ROOT>`：本仓库（`unity-mcp-monorepo`）的绝对路径
> - `<UNITY_PROJECT>`：目标 Unity 项目的根目录绝对路径
> 请在执行命令前替换为实际路径。

---

## 前置要求

- **Unity**：2021.3 LTS 或更高版本
- **Node.js**：≥ 18.0.0（server 运行依赖）
- **Git**：用于克隆本仓库

---

## 通用步骤：克隆仓库

```bash
git clone --recursive https://github.com/nantas/unity-mcp-monorepo.git
cd unity-mcp-monorepo
```

> `--recursive` 确保 `plugin/` 和 `server/` 两个 submodule 一并拉取。

---

## 步骤一：安装 Plugin（选择适用方式）

| 场景 | 方式 | 特点 |
|------|------|------|
| **开发环境** | 软链接 | 修改即时生效，适合迭代开发 |
| **发布环境** | 快照复制 | 独立副本，适合 Agent 部署或团队协作 |

### 方式 A：开发环境（软链接）

**macOS / Linux：**

```bash
cd <UNITY_PROJECT>/Packages
ln -s <MONOREPO_ROOT>/plugin com.anklebreaker.unity-mcp
```

**Windows（需要管理员权限或 Developer Mode）：**

```cmd
cd <UNITY_PROJECT>\Packages
mklink /D com.anklebreaker.unity-mcp <MONOREPO_ROOT>\plugin
```

> [!tip]
> 软链接方式下，对 `<MONOREPO_ROOT>/plugin` 的任何修改都会即时反映到 Unity 项目中。更新时只需在 monorepo 内执行 `git pull`。

> [!note]
> Windows 若无法创建软链接，可改用下方的发布环境方式安装，不影响 server 配置。

### 方式 B：发布环境（快照复制）

**macOS / Linux：**

```bash
cd <MONOREPO_ROOT>
./scripts/install-plugin.sh <UNITY_PROJECT>
```

**Windows：**

```powershell
cd <MONOREPO_ROOT>
.\scripts\install-plugin.ps1 -UnityProject <UNITY_PROJECT>
```

脚本会：
- 将 `plugin/` 的内容复制到 `<UNITY_PROJECT>/Packages/com.anklebreaker.unity-mcp`
- 排除 `.git/`、`.github/`、`docs/`、`CHANGELOG.md`、`.gitignore` 等开发文件
- 保留所有 `.meta` 文件和 `README.md`
- 若目标目录已存在，会先清理再重新复制（幂等）

> [!warning]
> **无论选择哪种方式，安装完成后请勿删除 monorepo 目录。** MCP server 的启动入口位于 `<MONOREPO_ROOT>/server/src/index.js`，删除 monorepo 将导致 MCP 客户端无法启动 server。

---

## 步骤二：安装 Server 依赖

```bash
cd <MONOREPO_ROOT>/server
npm install
```

---

## 步骤三：配置 MCP 客户端

根据你使用的 Agent 工具选择对应格式，将 `<MONOREPO_ROOT>` 替换为实际路径：

### `.mcp.json`（Pi / Claude Desktop）

保存到 Unity 项目根目录：

```json
{
  "mcpServers": {
    "unity-mcp": {
      "command": "node",
      "args": ["<MONOREPO_ROOT>/server/src/index.js"],
      "env": {
        "UNITY_BRIDGE_PORT": "7890",
        "UNITY_PORT_RANGE_START": "7890",
        "UNITY_PORT_RANGE_END": "7899",
        "UNITY_MCP_DEBUG": "false"
      },
      "directTools": [
        "unity_execute_code",
        "unity_get_compilation_errors",
        "unity_console_log",
        "unity_search_assets",
        "unity_script_create",
        "unity_script_read",
        "unity_script_update"
      ]
    }
  }
}
```

### `.codex/config.toml`（Codex CLI）

保存到 Unity 项目根目录的 `.codex/` 下：

```toml
[mcp_servers.unity-mcp]
command = "node"
args = ["<MONOREPO_ROOT>/server/src/index.js"]

[mcp_servers.unity-mcp.env]
UNITY_BRIDGE_PORT = "7890"
UNITY_PORT_RANGE_START = "7890"
UNITY_PORT_RANGE_END = "7899"
UNITY_MCP_DEBUG = "false"
```

---

## 端口与多实例配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `UNITY_BRIDGE_PORT` | `7890` | 默认桥接端口 |
| `UNITY_PORT_RANGE_START` | `7890` | 多实例端口范围起点 |
| `UNITY_PORT_RANGE_END` | `7899` | 多实例端口范围终点 |

**多实例工作流：**

1. 每个 Unity 项目启动时，plugin 在端口范围内自动选取空闲端口，并将信息写入共享注册表 `~/.local/share/UnityMCP/instances.json`
2. Node server 启动后读取注册表 + 扫描端口范围，自动发现所有运行中的 Unity 实例
3. Agent 调用 `unity_list_instances` 查看实例列表 → `unity_select_instance(port)` 选择目标 → 后续命令自动路由

如需修改端口范围，请同步修改：
- **MCP 客户端配置**中的 `UNITY_PORT_RANGE_START` / `UNITY_PORT_RANGE_END`
- **Unity 编辑器**中 `Edit > Project Settings > Unity MCP` 的端口范围设置

---

## 验证安装

1. 打开 Unity 编辑器，检查 **Package Manager** 中是否出现 `AnkleBreaker Unity MCP`
2. 检查 Unity Console 中是否有 `[MCP Bridge]` 或 `[AB-UMCP]` 前缀的启动日志
3. 在 MCP 客户端中调用 `unity_list_instances`，确认返回至少一个实例

---

## 故障排查

### 软链接创建失败（Windows）

**现象**：`mklink` 报 "You do not have sufficient privilege"

**解决**：
- 以管理员身份运行命令提示符，或
- 开启 Windows Developer Mode（设置 → 隐私和安全性 → 开发者选项 → 开启 Developer Mode）

> 如果无法启用软链接，请改用 [发布环境安装方式](#方式-b发布环境快照复制)。

### Server 启动失败：找不到模块

**现象**：MCP 客户端报 `Error: Cannot find module '@modelcontextprotocol/sdk'`

**解决**：确认已在 `<MONOREPO_ROOT>/server` 目录执行 `npm install`

### Unity Console 无 MCP 启动日志

**现象**：打开 Unity 后 Console 中没有任何 `[MCP Bridge]` 日志

**解决**：
1. 确认 plugin 已正确安装（Package Manager 中可见）
2. 确认 Unity 非 batch mode（plugin 在 batch mode 下不启动 HTTP 桥）
3. 检查 `Edit > Project Settings > Unity MCP` 中插件是否被禁用

---

## 两种安装方式对比

| 维度 | 开发环境（软链接） | 发布环境（快照复制） |
|------|-------------------|---------------------|
| plugin 来源 | 软链接到 monorepo | 脚本快照复制 |
| 修改是否即时生效 | 是 | 否 |
| 是否需要保留 monorepo | **是**（server 依赖） | **是**（server 依赖） |
| 适合场景 | 迭代开发、调试 | Agent 自动部署、团队协作 |
| 更新方式 | `git pull` 即更新 | 重新运行安装脚本 |
