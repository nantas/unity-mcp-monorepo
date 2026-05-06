<p align="center">
  <img src="plugin/icon.png" alt="AnkleBreaker MCP" width="180" />
</p>

# AnkleBreaker Unity MCP — Monorepo

> 通过 git submodule 统一管理 Unity MCP 的 **Plugin**（Unity 编辑器插件）和 **Server**（Node.js MCP Server），实现一站式克隆、安装和更新。

[![Plugin](https://img.shields.io/badge/plugin-v2.27.0-blue?logo=unity)](plugin/)
[![Server](https://img.shields.io/badge/server-v2.28.2-green?logo=node.js)](server/)
[![License](https://img.shields.io/badge/license-AnkleBreaker%20Open%20v1.0-orange)](LICENSE)

---

## 它是什么

**AnkleBreaker Unity MCP** 是目前最全面的 Unity [Model Context Protocol](https://modelcontextprotocol.io) 集成方案，提供 **288 个工具**，覆盖 **30+ 个功能类别**，让 Claude、Cursor、Windsurf 等 AI 助手直接操控 Unity Editor。

本 monorepo 将两个核心组件以 submodule 形式统一管理：

| 组件 | 说明 |
|------|------|
| **[plugin/](plugin/)** | Unity 编辑器插件（UPM 包），在 Editor 内运行 HTTP 桥接服务 |
| **[server/](server/)** | Node.js MCP Server，通过 stdio 与 AI 助手通信，通过 HTTP 与 Plugin 通信 |

### 通信架构

```
AI Assistant (Claude / Cursor / Windsurf)
    ↕  MCP Protocol (stdio / JSON-RPC)
Node.js MCP Server (server/)
    ↕  HTTP REST (localhost)
Unity Editor Plugin (plugin/)
    ↕  Unity Editor APIs
Unity Engine
```

---

## 功能亮点

### 🎮 全面覆盖 Unity 工作流

| 类别 | 能力 |
|------|------|
| **场景管理** | 打开/保存/新建场景，层级树遍历（分页） |
| **GameObject** | 创建/删除/复制，Transform，父子关系，激活状态 |
| **组件** | 添加/移除，读写任意序列化属性，引用绑定，批量连线 |
| **资源** | 导入/删除/搜索，创建 Prefab 和 Material |
| **脚本** | 创建/读取/更新 C# 脚本 |
| **构建** | 多平台构建（Win/macOS/Linux/Android/iOS/WebGL） |
| **控制台 & 编译** | 日志读取/清除；CompilationPipeline 错误捕获 |
| **动画** | Clips、Controllers、Parameters、States、Transitions、Blend Trees |
| **物理** | Raycast、Overlap、碰撞矩阵、重力设置 |
| **地形** | Heightmap、Layers、Trees、Details、Holes |
| **导航** | NavMesh 烘焙、Agents、Obstacles、Off-mesh Links |
| **Shader Graph** | 列表/创建/打开，节点和连线 CRUD |
| **Amplify Shader** | 完整图编辑（需 ASE 插件） |
| **粒子系统** | 创建、检查、模块编辑 |
| **UI 系统** | Canvas、UI 元素、Layout、Event System |
| **音频** | AudioSource、AudioMixer、播放控制 |
| **灯光** | 灯光管理、环境光/Skybox、Lightmap 烘焙、Reflection Probes |
| **性能分析** | Profiler、Frame Debugger、Memory Profiler |
| **多实例** | 自动发现多个运行中的 Unity Editor |
| **多 Agent** | 会话追踪、动作日志、队列化执行 |

### 🏗️ 架构特色

- **两阶工具系统** — ~70 个 Core 工具直接暴露，~130+ 个 Advanced 工具通过 `unity_advanced_tool` 代理按需加载，避免超出 MCP 客户端工具数限制
- **Play Mode 韧性** — 通过 `SessionState` 持久化状态，Domain Reload 后自动恢复
- **端口亲和** — 插件记忆上次使用的端口，重启时优先回收，减少多项目场景端口漂移
- **心跳检测** — 每 30s 更新注册表 `lastSeen`，Server 侧通过 staleness 检测区分编译中与已崩溃的实例
- **多 Agent 队列** — Ticket-based round-robin 调度，读操作 batch（5/帧），写操作串行（1/帧）

---

## 快速开始

### 前置要求

- **Unity** 2021.3 LTS+
- **Node.js** ≥ 18.0.0
- **Git**

### 1. 克隆仓库

```bash
git clone --recursive https://github.com/nantas/unity-mcp-monorepo.git
cd unity-mcp-monorepo
```

### 2. 安装 Server 依赖

```bash
cd server
npm install
```

### 3. 安装 Plugin 到 Unity 项目

根据你的场景选择安装方式：

| 场景 | 方式 | 特点 |
|------|------|------|
| **开发环境** | [软链接](docs/install-workflow.md#方式-a开发环境软链接) | 修改即时生效，适合迭代开发 |
| **发布环境** | [快照脚本](docs/install-workflow.md#方式-b发布环境快照复制) | 独立副本，适合 Agent 部署或团队协作 |

**开发环境（推荐）：**

```bash
cd <UNITY_PROJECT>/Packages
ln -s <MONOREPO_ROOT>/plugin com.anklebreaker.unity-mcp
```

**发布环境：**

```bash
# macOS / Linux
./scripts/install-plugin.sh <UNITY_PROJECT>

# Windows
.\scripts\install-plugin.ps1 -UnityProject <UNITY_PROJECT>
```

### 4. 配置 MCP 客户端

将以下配置保存到 Unity 项目根目录的 `.mcp.json`（Pi / Claude Desktop）：

```json
{
  "mcpServers": {
    "unity-mcp": {
      "command": "node",
      "args": ["<MONOREPO_ROOT>/server/src/index.js"],
      "env": {
        "UNITY_BRIDGE_PORT": "7890",
        "UNITY_PORT_RANGE_START": "7890",
        "UNITY_PORT_RANGE_END": "7899"
      }
    }
  }
}
```

> 完整配置（包括 Codex CLI、端口自定义、`directTools` 列表）详见 [安装工作流文档](docs/install-workflow.md)。

### 5. 验证

1. 打开 Unity Editor → Package Manager 中应出现 `AnkleBreaker Unity MCP`
2. Console 中应有 `[MCP Bridge] Server started on port 7890` 日志
3. 在 MCP 客户端中调用 `unity_list_instances`，确认返回至少一个实例

---

## 项目结构

```
unity-mcp-monorepo/
├── plugin/           # submodule → unity-mcp-plugin (C# Unity Editor Plugin)
├── server/           # submodule → unity-mcp-server (Node.js MCP Server)
├── docs/             # 跨组件设计文档 & 安装指南
│   └── install-workflow.md
├── scripts/          # 发布环境安装脚本
│   ├── install-plugin.sh
│   └── install-plugin.ps1
├── openspec/         # OpenSpec 工件（specs/ + changes/）
└── AGENTS.md         # AI Agent 开发指引
```

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `UNITY_BRIDGE_PORT` | `7890` | 默认桥接端口 |
| `UNITY_PORT_RANGE_START` | `7890` | 多实例端口扫描起点 |
| `UNITY_PORT_RANGE_END` | `7899` | 多实例端口扫描终点 |
| `UNITY_BRIDGE_TIMEOUT` | `60000` | 请求超时（ms） |
| `UNITY_REGISTRY_STALENESS_TIMEOUT` | `300000` | 注册表条目过期（ms） |
| `UNITY_RESPONSE_HARD_LIMIT` | `4194304` | 响应硬限制（4MB） |
| `UNITY_MCP_DEBUG` | `false` | 调试日志开关 |

---

## 文档

| 文档 | 说明 |
|------|------|
| [安装工作流](docs/install-workflow.md) | 完整安装指南：开发环境 vs 发布环境 |
| [Plugin README](plugin/README.md) | Unity 插件详细功能、配置、FAQ |
| [Server README](server/README.md) | MCP Server 配置、环境变量、故障排查 |
| [AGENTS.md](AGENTS.md) | AI Agent 开发指引（命令模块、工作流、安全守则） |

---

## 相关项目

- **[unity-mcp-plugin](https://github.com/AnkleBreaker-Studio/unity-mcp-plugin)** — Unity Editor 插件（UPM 包）
- **[unity-mcp-server](https://github.com/AnkleBreaker-Studio/unity-mcp-server)** — Node.js MCP Server
- **[Model Context Protocol](https://modelcontextprotocol.io)** — 驱动此集成的开放标准
- **[Claude Desktop](https://claude.ai/download)** — Anthropic 的 AI 助手，内置 MCP 支持
- **[AnkleBreaker Studio](https://github.com/AnkleBreaker-Studio)** — 背后的游戏工作室

---

## License

AnkleBreaker Open License v1.0 — see [LICENSE](LICENSE)

本许可要求：(1) 保留版权声明，(2) 在使用本工具构建的产品中显示 **"Made with AnkleBreaker MCP"**（或 "Powered by AnkleBreaker MCP"）归属标识（个人/教育用途豁免），(3) **禁止转售** — 不得出售、再授权或商业分发本软件及其衍生品。详见 [LICENSE](LICENSE)。
