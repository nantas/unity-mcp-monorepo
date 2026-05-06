# AnkleBreaker Unity MCP — Mono Repo

通过 git submodule 统一管理 Unity MCP 的 plugin（Unity 编辑器插件）和 server（Node.js MCP Server）两个组件，OpenSpec 工件集中管理。

```
unity-mcp/
├── plugin/       # submodule → unity-mcp-plugin (C# Unity Editor Plugin)
├── server/       # submodule → unity-mcp-server (Node.js MCP Server)
├── docs/         # 跨组件设计文档
└── openspec/     # OpenSpec 工件（specs/ + changes/）
```

## Remote

| 仓库 | origin | upstream |
|------|--------|----------|
| monorepo | `git@github.com:nantas/unity-mcp-monorepo.git` | — |
| plugin | `git@github.com:nantas/unity-mcp-plugin.git` | `AnkleBreaker-Studio/unity-mcp-plugin` |
| server | `git@github.com:nantas/unity-mcp-server.git` | `AnkleBreaker-Studio/unity-mcp-server` |

所有修改推送到 `origin`（fork），`upstream` 只读，用于同步上游更新。

---

## 安装工作流

将 Unity MCP 安装到目标 Unity 项目的完整指南见 `docs/install-workflow.md`。本文档覆盖两种安装场景：

| 场景 | 方式 | 说明 |
|------|------|------|
| **开发环境** | 软链接 `plugin/` 到 Unity `Packages/` | 修改即时生效，适合本地迭代 |
| **发布环境** | 快照脚本复制 plugin 到 `Packages/` | 独立副本，适合 Agent 部署或团队协作 |

两种场景下 server 均从 monorepo 的 `server/` 目录启动，因此**安装完成后不可删除 monorepo**。文档同时提供了 `.mcp.json`（Pi / Claude Desktop）和 `.codex/config.toml`（Codex CLI）的配置模板。

> 详细步骤、端口配置、验证方法和故障排查 → [`docs/install-workflow.md`](docs/install-workflow.md)

---

## 通信架构

```
AI Assistant (Claude/Cursor/Windsurf)
    ↕  MCP Protocol (stdio / JSON-RPC)
Node.js MCP Server (server/)
    ↕  HTTP REST (localhost)
Unity Editor C# Plugin (plugin/Editor/)
    ↕  Unity Editor APIs
Unity Engine
```

- **Server** 通过 `@modelcontextprotocol/sdk` 的 stdio transport 与 AI Assistant 通信
- **Server** 通过 HTTP (`127.0.0.1:7890-7899`) 与 Unity Editor 内的 Plugin 通信
- **Plugin** 在 Unity Editor 主线程上执行实际的编辑器操作
- 所有跨边界通信使用 JSON；Plugin 侧使用 `MiniJson.cs` 做序列化

---

## Plugin 仓库（Unity 编辑器侧）

### 结构

```
plugin/
├── package.json              # UPM 包描述 (com.anklebreaker.unity-mcp)
├── Editor/                   # 全部 C# 源码（Editor 文件夹 = 编辑器-only）
│   ├── AnkleBreaker.UnityMCP.Editor.asmdef
│   ├── MCPBridgeServer.cs      # HTTP 桥接服务器（核心入口）
│   ├── MCPRequestQueue.cs      # 多 Agent ticket 队列（round-robin 调度）
│   ├── MCPInstanceRegistry.cs  # 多实例发现注册表 + 心跳
│   ├── MCPSettingsManager.cs   # EditorPrefs 持久化设置
│   ├── MCPContextManager.cs    # Project Context (Assets/MCP/Context/)
│   ├── MCPActionHistory.cs     # 全局动作历史（ring buffer + 持久化）
│   ├── MCPDashboardWindow.cs   # Editor 窗口 Dashboard
│   ├── MCPAgentSession.cs      # Agent 会话追踪
│   ├── MiniJson.cs             # JSON 序列化（无外部依赖）
│   └── MCP*Commands.cs         # 各功能域命令模块（见下表）
└── docs/                       # 截图/GIF 等展示素材
```

### 命令模块索引（按功能域）

| 文件 | 功能域 | 核心能力 |
|------|--------|----------|
| `MCPSceneCommands.cs` | Scene | open/save/new, hierarchy 树遍历 |
| `MCPGameObjectCommands.cs` | GameObject | create/delete/duplicate, transform, reparent, active |
| `MCPComponentCommands.cs` | Component | add/remove, get/set property, set reference, batch wire |
| `MCPAssetCommands.cs` | Asset | list/import/delete, create prefab/material |
| `MCPScriptCommands.cs` | Script | create/read/update C# 脚本 |
| `MCPBuildCommands.cs` | Build | 多平台构建 (Win/macOS/Linux/Android/iOS/WebGL) |
| `MCPConsoleCommands.cs` | Console | 读取/清除日志；CompilationPipeline 错误捕获 |
| `MCPEditorCommands.cs` | Editor | execute menu item, execute C# code (Roslyn), play mode |
| `MCPScreenshotCommands.cs` | Screenshot | Game/Scene View 截屏（inline image） |
| `MCPAnimationCommands.cs` | Animation | clips, controllers, parameters, states, transitions, blend trees |
| `MCPPrefabCommands.cs` | Prefab (Scene) | info, overrides, apply/revert, unpack |
| `MCPPrefabAssetCommands.cs` | Prefab Asset | hierarchy, add/remove GO, set property/reference |
| `MCPShaderGraphCommands.cs` | Shader Graph | list/create/open, node/edge CRUD（需 Shader Graph 包） |
| `MCPAmplifyCommands.cs` | Amplify Shader | 完整图编辑（需 ASE 插件） |
| `MCPTerrainCommands.cs` | Terrain | heightmap, layers, trees, details, holes, neighbors |
| `MCPPhysicsCommands.cs` | Physics | raycast, overlap, collision matrix, gravity |
| `MCPLightingCommands.cs` | Lighting | lights, environment, skybox, bake, reflection probes |
| `MCPAudioCommands.cs` | Audio | AudioSources, Mixers, play/stop |
| `MCPNavigationCommands.cs` | Navigation | NavMesh bake, agents, obstacles, off-mesh links |
| `MCPParticleCommands.cs` | Particle System | create, main/emission/shape module 编辑 |
| `MCPUICommands.cs` | UI | Canvas, UI elements, text, image, layout |
| `MCPInputCommands.cs` | Input System | action maps, actions, bindings（需 Input System 包） |
| `MCPProfilerCommands.cs` | Profiler | enable, stats, frame data, analyze |
| `MCPMemoryProfilerCommands.cs` | Memory Profiler | breakdown, top consumers, snapshots（需 MemoryProfiler 包） |
| `MCPGraphicsCommands.cs` | Graphics | scene/game capture, mesh/material/texture/renderer info |
| `MCPSelectionCommands.cs` | Selection | get/set, find by type/tag/layer/name |
| `MCPSearchCommands.cs` | Search | by component/tag/layer/name/shader, asset search, missing refs |
| `MCPProjectCommands.cs` | Project | project info, packages, render pipeline |
| `MCPProjectSettingsCommands.cs` | Settings | quality, physics, time, player, render pipeline |
| `MCPPackageManagerCommands.cs` | Packages | list/add/remove/search packages |
| `MCPAssemblyDefCommands.cs` | Assembly Defs | create/inspect .asmdef, references, platforms |
| `MCPScriptableObjectCommands.cs` | ScriptableObject | create, inspect, modify |
| `MCPConstraintCommands.cs` | Constraints | position/rotation/scale/aim/parent constraints |
| `MCPTagLayerCommands.cs` | Tags & Layers | list/add tags, assign tag/layer/static |
| `MCPTextureCommands.cs` | Texture | info, import settings, sprite/normal map 切换 |
| `MCPSpriteAtlasCommands.cs` | SpriteAtlas | create, add/remove sprites, settings, delete |
| `MCPUndoCommands.cs` | Undo | perform, redo, history, clear |
| `MCPPrefsCommands.cs` | Prefs | EditorPrefs / PlayerPrefs CRUD |
| `MCPScenarioCommands.cs` | MPPM | multiplayer scenarios（需 MPPM 包） |
| `MCPUMACommands.cs` | UMA | Slot/Overlay/WardrobeRecipe, DCA equip（需 UMA 2） |
| `MCPTestRunnerCommands.cs` | Testing | EditMode/PlayMode 测试运行（异步回调 deferred） |
| `MCPSelfTest.cs` | Self Test | 启动时自检，探测所有命令模块 |
| `MCPUpdateChecker.cs` | Update | GitHub release 检查 |
| `MCPWelcomeWindow.cs` | UI | 首次安装欢迎窗口 |
| `MCPActionHistoryWindow.cs` | UI | 动作历史查看窗口 |
| `MCPToolbarElement.cs` | UI | 工具栏快捷按钮 |

### 关键设计模式

- **Play Mode 韧性**：`SessionState` + `AssemblyReloadEvents.beforeAssemblyReload` 持久化运行状态，domain reload 后自动恢复
- **多 Agent 队列**：`MCPRequestQueue` 实现 ticket-based round-robin，每 Agent 独立 FIFO；读操作 batch（最多 5 个/帧），写操作串行（1 个/帧）
- **心跳机制**：`MCPInstanceRegistry` 每 30s 更新 `lastSeen`，server 侧通过 staleness 检测（>5min）识别崩溃
- **Port Affinity**：插件通过 `EditorPrefs` 记忆上次端口，重启时优先 reclaim，减少多项目场景下的端口漂移
- **命令路由**：`MCPBridgeServer` 的 `HandleRequest` 将 URL path（如 `gameobject/create`）映射到对应的 `MCP*Commands` 静态方法

---

## Server 仓库（MCP Server 侧）

### 结构

```
server/
├── package.json              # npm 包描述 (anklebreaker-unity-mcp)
├── manifest.json             # Claude Desktop MCP 市场清单
├── src/
│   ├── index.js              # MCP Server 主入口（stdio transport + tool 注册）
│   ├── config.js             # 环境变量配置（Hub 路径、端口范围、超时等）
│   ├── unity-editor-bridge.js  # HTTP 客户端：sendCommand + 重试/队列模式切换
│   ├── unity-hub.js            # Unity Hub CLI 封装（--headless / legacy 语法兼容）
│   ├── instance-discovery.js   # 多实例发现：注册表读取 + 端口扫描 + 验证
│   ├── state-persistence.js    # 状态持久化（跨 Claude 会话）
│   ├── tool-tiers.js           # 两阶工具分层：core vs advanced
│   ├── uma-bridge.js           # UMA 工具专用桥接
│   └── tools/
│       ├── editor-tools.js     # Unity Editor 工具定义 (~4400 行，~60 core tools)
│       ├── hub-tools.js        # Unity Hub 工具定义
│       ├── instance-tools.js   # 多实例管理工具
│       ├── context-tools.js    # Project Context 工具
│       └── uma-tools.js        # UMA 高级工具
├── tests/
│   └── multi-agent-stress-test.mjs  # 多 Agent 压测（支持 --mock 模式）
└── docs/                       # 展示素材
```

### 关键文件索引

| 文件 | 职责 |
|------|------|
| `src/index.js` | MCP Server 入口：创建 `@modelcontextprotocol/sdk` Server，注册 tools/resources handlers，注入 per-agent 上下文 |
| `src/unity-editor-bridge.js` | 与 Unity Plugin HTTP 桥通信：自动检测队列模式（`POST /api/queue/submit`）vs 传统同步模式（`POST /api/{command}`），指数退避重试 |
| `src/instance-discovery.js` | 实例发现核心：读取共享注册表 → ping 验证 → 端口扫描 fallback；支持 port affinity、compile-time resilience、crash detection |
| `src/tool-tiers.js` | 两阶工具系统：`splitToolTiers()` 将 ~280 tools 拆分为 ~60 core（直接暴露）+ ~200 advanced（通过 `unity_advanced_tool` 代理） |
| `src/config.js` | 集中配置：所有环境变量默认值，包括响应大小限制（soft 2MB / hard 4MB，防 Write EOF） |
| `src/tools/editor-tools.js` | 最大的工具定义文件，每个 tool = `{ name, description, inputSchema, handler }` |

### 两阶工具系统

- **Core tools**（~60 个）：始终直接暴露给 MCP client，涵盖场景管理、GameObject CRUD、组件操作等高频操作
- **Advanced tools**（~200+ 个）：通过 `unity_advanced_tool` 统一代理 + `unity_list_advanced_tools` 列举，按需懒加载
- **Lazy dispatch**：`toolNameToRoute()` 从工具名推导 HTTP 路由（如 `unity_terrain_create` → `terrain/create`），新增 Plugin 命令无需重启 Server

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `UNITY_HUB_PATH` | `C:\Program Files\Unity Hub\Unity Hub.exe` | Unity Hub 可执行文件路径 |
| `UNITY_BRIDGE_PORT` | `7890` | 默认桥接端口（fallback） |
| `UNITY_BRIDGE_TIMEOUT` | `60000` | 请求超时（ms） |
| `UNITY_PORT_RANGE_START/END` | `7890` / `7899` | 多实例端口扫描范围 |
| `UNITY_REGISTRY_STALENESS_TIMEOUT` | `300000` | 注册表条目过期（ms），默认 5min |
| `UNITY_RESPONSE_HARD_LIMIT` | `4194304` | 响应硬限制（4MB），超限返回分页提示 |
| `UNITY_MCP_DEBUG` | `false` | 调试日志开关 |

---

## 开发命令

### Server

```bash
cd server
npm install          # 安装依赖（仅 @modelcontextprotocol/sdk）
npm start            # 启动 MCP Server（stdio 模式）
npm run dev          # watch 模式开发
npm run pack         # 打包 .mcpb 文件（需 @anthropic-ai/mcpb）

# 多 Agent 压测（mock 模式，无需 Unity）
node tests/multi-agent-stress-test.mjs --mock --agents 5 --requests 6
```

### Plugin

- 无需额外构建命令，直接在 Unity Editor 中开发
- 通过 Unity Package Manager → Add package from git URL 安装
- 修改 C# 代码后 Unity 自动编译（CompilationPipeline）
- Console 查看 `[MCP Bridge]` / `[AB-UMCP]` / `[Unity MCP Queue]` 日志

---

## 核心工作流

### 铁律：先 Submodule，后 Monorepo

**任何 `git add` / `git commit` / `git push` 之前，必须先检查 submodule 是否有未提交的改动。**

```bash
# 1. 检查 submodule 状态
git submodule status --recursive      # + 号前缀 = 有未提交改动
cd plugin && git status --short
cd ../server && git status --short

# 2. 如有改动，先在子模块内提交
cd plugin && git checkout main && git add -A && git commit -m "..." && git push origin main
cd ../server && git checkout main && git add -A && git commit -m "..." && git push origin main

# 3. 回到 monorepo 提交指针更新和 monorepo 文件
cd ..
git add plugin server openspec/ docs/
git commit -m "feat: <描述整体变更>"
git push origin main
```

> **禁止**在 monorepo 中直接 `git add plugin/` 来提交子模块内部文件 — monorepo 只记录指针（commit hash），不记录子模块内容。

### OpenSpec Apply 后的提交

OpenSpec 工作流技能位于 `.pi/`（Pi）和 `.codex/`（Codex CLI）中。完成 `apply` 后，遵循上述铁律，确保 `openspec/` 和 submodule 指针一并提交：

```bash
# 先完成 submodule 提交（步骤同上）
# ...

# 然后回到 monorepo
git add openspec/ plugin server
git commit -m "feat: apply <change-name>"
git push origin main
```

### 上游同步（仅在用户要求时执行）

```bash
git submodule foreach 'git fetch upstream && git merge upstream/main'
git add plugin server
git commit -m "chore: sync submodules from upstream"
```

---

## 常见陷阱

| 现象 | 原因 | 解决 |
|------|------|------|
| `git status` 显示 submodule `modified` | 子模块有未提交的改动 | 进入子模块 commit 或 stash |
| 子模块处于 detached HEAD | `git submodule update` 默认行为 | `cd plugin && git checkout main` |
| push 到 upstream 被拒 | upstream 为只读 | 推送到 origin（fork） |
| Unity Console 无 `[MCP Bridge]` 启动日志 | Plugin 未安装或 batch mode 被检测 | 检查 Package Manager 中插件状态；确认非 batch mode |
| Server 报 "Connection failed" | Unity Editor 未运行或插件 HTTP 桥未启动 | 检查 Unity 是否打开，Console 是否有启动日志 |
| 多 Agent 时命令路由到错误项目 | 未使用 `port` 参数进行 parallel-safe routing | 每次 tool call 都带上 `port: <instance_port>` |
| Codex CLI 启动后断开连接 | Plugin 的 `console.debug` 写到了 stdout | 确保所有日志写 stderr（已修复于 v2.28.2） |

---

## 安全守则

- **禁止** `git push` 到 `upstream`
- **禁止**在 monorepo 中直接编辑子模块文件后不进入子模块提交
- **禁止** `git push --force`
