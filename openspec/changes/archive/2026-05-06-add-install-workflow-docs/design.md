## Context

目前 monorepo 缺少驻留本仓库的安装指南。开发者和 Agent 配置 Unity MCP 时，依赖外部项目（如 neonnew）的零散文档，导致：
- 软链接 vs 快照复制的选择不明确
- MCP 客户端配置散落在各项目，路径占位符未统一
- 无自动化脚本，Agent 手动复制文件易遗漏 `.meta`

本 change 将安装工作流文档和配套脚本纳入 monorepo，提供两种场景的单一事实来源。

## Goals / Non-Goals

**Goals:**
- 提供一份 `docs/install-workflow.md`，驻留 monorepo，覆盖开发与发布两种安装场景
- 提供跨平台快照脚本（sh + ps1），自动排除开发文件并保留 `.meta`
- 提供 `.mcp.json` 和 `.codex/config.toml` 双格式配置模板，含 `<MONOREPO_ROOT>` 占位符
- 明确说明发布环境下 monorepo 必须保留，因为 server 仍需从中启动

**Non-Goals:**
- 不修改 plugin 或 server 的源代码
- 不提供 UPM git URL 安装方式以外的包管理集成
- 不涉及 Unity Hub 的自动化调用或项目创建

## Decisions

### 1. 文档使用 `<MONOREPO_ROOT>` 和 `<UNITY_PROJECT>` 占位符
- **Rationale**: 仓库克隆位置由用户决定，硬编码路径不可行。占位符模式与现有 neonnew 项目指南一致，Agent 可通过字符串替换快速生成实际配置。
- **Alternative**: 使用环境变量注入。Rejected——MCP 客户端配置（如 `.mcp.json`）不支持 shell 变量展开，且跨平台兼容性差。

### 2. 快照脚本排除 `.git`、`.github`、`docs`、`CHANGELOG.md`、`.gitignore`
- **Rationale**: 发布环境只需要运行 plugin 所需的文件（`Editor/`、`package.json`、`.meta`、图标等），开发元数据会增加体积并可能引发 Unity 的无关导入警告。
- **Alternative**: 不排除 `.git`，让用户在 Packages 目录下直接管理 submodule。Rejected——Unity Packages 目录内嵌 `.git` 会导致 UPM 和 Unity 的版本控制行为异常。

### 3. 脚本保留 `README.md`
- **Rationale**: `README.md` 包含版本和基本说明，对后续排查有帮助；其 `.meta` 文件若缺失会导致 Unity 报 missing meta。脚本通过显式 `cp` 保留。

### 4. 双格式 MCP 配置（JSON + TOML）
- **Rationale**: Pi / Claude Desktop 使用 `.mcp.json`，Codex CLI 使用 `.codex/config.toml`。覆盖两种格式可服务不同 Agent 环境。
- **Alternative**: 仅提供一种格式。Rejected——团队内同时使用 Pi 和 Codex CLI，单一格式会阻塞部分工作流。

### 5. 脚本置于 monorepo 根目录的 `scripts/` 下
- **Rationale**: 与文档共同分发，用户 clone monorepo 后即可调用。不放在 plugin 或 server 子目录内，因为脚本跨组件（同时操作 plugin 和引用 server 路径）。

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| 软链接在 Windows 上需要管理员权限或 Developer Mode | 文档中明确标注 Windows 软链接限制，并引导 Windows 用户优先使用快照脚本或 mklink |
| 用户误删 monorepo 导致 server 不可用 | 文档中在发布环境章节用 `> [!warning]` 高亮提示："安装完成后请勿删除 monorepo，MCP server 仍需从此处启动" |
| 快照复制后 plugin 更新不同步 | 文档说明：发布环境下更新需重新运行脚本；开发环境则通过 `git pull` 自动同步 |
| `<MONOREPO_ROOT>` 占位符替换遗漏 | 配置模板中占位符使用尖括号包裹，视觉上醒目，并在文档步骤中强调替换 |

## Migration Plan

- 无迁移需求。本 change 为纯新增文档和脚本，不影响现有安装方式。
- 后续可将 neonnew 项目中的安装指南替换为指向本仓库 `docs/install-workflow.md` 的链接，统一维护源。

## Open Questions

- 是否需要为 Cursor 编辑器提供 `.cursor/mcp.json` 配置模板？（当前仅覆盖 Pi 和 Codex CLI）
- 快照脚本是否需要支持 `--dry-run` 模式以便用户预览复制内容？
