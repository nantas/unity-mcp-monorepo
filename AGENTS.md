# AnkleBreaker Unity MCP — Mono Repo

通过 git submodule 统一管理 Unity MCP 的 plugin 和 server 两个组件，OpenSpec 工件集中管理。

```
unity-mcp/
├── plugin/       # submodule → unity-mcp-plugin
├── server/       # submodule → unity-mcp-server
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

## 常见陷阱

| 现象 | 原因 | 解决 |
|------|------|------|
| `git status` 显示 submodule `modified` | 子模块有未提交的改动 | 进入子模块 commit 或 stash |
| 子模块处于 detached HEAD | `git submodule update` 默认行为 | `cd plugin && git checkout main` |
| push 到 upstream 被拒 | upstream 为只读 | 推送到 origin（fork） |

## 安全守则

- **禁止** `git push` 到 `upstream`
- **禁止**在 monorepo 中直接编辑子模块文件后不进入子模块提交
- **禁止** `git push --force`
