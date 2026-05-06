## Why

目前 monorepo 缺乏一份统一的安装工作流文档，导致开发者和 Agent 在配置 Unity MCP 环境时依赖外部项目（如 neonnew）的零散指南，步骤不一致且维护困难。需要一份驻留在本仓库、覆盖开发与发布两种场景的通用指南，确保任何 Unity 项目都能按统一路径完成 plugin + server 的安装与 MCP 客户端配置。

## What Changes

- 新增 `docs/install-workflow.md`：通用安装工作流文档，覆盖开发环境和发布环境两种安装场景，包含 MCP 客户端配置模板（`.mcp.json` / `.codex/config.toml`）。
- 新增 `scripts/install-plugin.sh`（macOS/Linux）和 `scripts/install-plugin.ps1`（Windows）：快照安装脚本，用于将 plugin 内容干净复制到目标 Unity 项目的 `Packages/` 目录（排除 `.git`、`.github`、开发文档等非运行文件）。
- 脚本自动保留 `.meta` 文件，确保 Unity 资源引用不丢失。
- 文档中明确说明：发布环境安装完成后**不可删除 monorepo**，因为 MCP server 仍需从 monorepo 的 `server/` 目录启动。

## Capabilities

### New Capabilities
- `install-workflow-dev`: 开发环境安装 — 将 monorepo 的 `plugin/` 软链接到 Unity 项目的 `Packages/com.anklebreaker.unity-mcp`，并配置 MCP 客户端指向 monorepo 内的 server。
- `install-workflow-release`: 发布环境安装 — 通过脚本将 `plugin/` 快照复制到 Unity 项目的 `Packages/` 目录，并配置 MCP 客户端指向 monorepo 内的 server（monorepo 保留作为 server 源）。

### Modified Capabilities
<!-- 无现有 spec 级别的需求变更 -->

## Impact

- 新增文件：`docs/install-workflow.md`、`scripts/install-plugin.sh`、`scripts/install-plugin.ps1`
- 无现有代码、API 或依赖变更
- 文档对 `<MONOREPO_ROOT>` 和 `<UNITY_PROJECT>` 使用占位符，用户需替换为实际路径
