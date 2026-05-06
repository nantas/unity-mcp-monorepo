## Context

`unity_scene_hierarchy` 当前在 137 节点 prefab 上产生 ~19K tokens 响应，其中 ~35% 为 pretty-print 缩进开销，~12% 为 `position`/`tag`/`layer` 等 LLM 极少访问的字段。这已经触发过 `UNITY_RESPONSE_HARD_LIMIT`（4MB）和 `Write EOF` 问题，导致 LLM 被迫用多轮 `parentPath` 子树查询来探索场景，效率低下。

本次优化涉及两个组件（Server Node.js + Plugin C#），跨层改动但无协议变更，属于典型的序列化层优化。

## Goals / Non-Goals

**Goals:**
- 将 `unity_scene_hierarchy` 单节点 token 开销从 ~104 tok 降至 ~38 tok（-63% 每节点）
- 对 137 节点场景整体从 ~19K → ~10K tokens（-47%）
- 不增加 LLM 的多轮调用负担：默认值即最优，按需显式开启字段
- 保持所有现有 API 的向后兼容（参数默认不传递时行为变更但无破坏性错误）

**Non-Goals:**
- 不改变 HTTP 通信协议或 URL 路由
- 不改动 `gameobject_info` 等详情查询工具的行为
- 不新增 hierarchy 查询的过滤/搜索能力（如按组件类型过滤）
- 不优化 `components` 列表的 token 开销（当前 ~25-40 tok/节点，保留为 high-value 字段）

## Decisions

### 1. Pretty Print 全局消除（所有 tools）
**决策**: 将 `server/src/tools/` 下所有 `JSON.stringify(data, null, 2)` 统一改为 `JSON.stringify(data)`。
**理由**: 
- MCP 协议通过 stdio 传输 JSON，无需人类可读格式；LLM 解析 compact JSON 能力无差异。
- 全局消除比仅针对 `unity_scene_hierarchy` 更一致，避免未来新增 tool 时重复此问题。
- 风险极低：此改动不改变数据结构，只改变序列化格式。

### 2. 默认精简 Hierarchy 字段
**决策**: `includeTransforms`/`includeTag`/`includeLayer` 默认 `false`，`includeInstanceId` 默认 `true`。
**理由**:
- 实测 LLM 对 hierarchy 的 95%+ 查询目的是"了解结构 + 组件分布"，不需要位置/标签/层级。
- `instanceId` 仍为多数操作（delete/set_transform）所需，暂时保留默认 `true`。未来可进一步通过 `includeInstanceId: false` 降至 ~7.6K tokens（-60%）。
- 与 `gameobject_info` 形成分层：hierarchy 是"骨架"，info 是"详情"。

**替代方案考虑**: 默认全部 `true`（与现有行为一致）+ 文档建议 LLM 传 `false`。否决原因：LLM 通常不会主动阅读工具文档来优化参数，默认行为必须自带最优 token 效率。

### 3. Prefab Asset Hierarchy 同步优化
**决策**: `MCPPrefabAssetCommands.cs` 的 `BuildHierarchyNode` 同步增加 `includeTransforms` 参数。
**理由**:
- Prefab 版本额外输出 `localPosition`/`localRotation`/`localScale`（9 个浮点数 + 3 层嵌套），token 开销比 Scene 版本更大。
- 保持 Scene 和 Prefab hierarchy API 的行为一致性，减少 LLM 的学习成本。

### 4. 字段控制仅通过 `args` 字典透传
**决策**: Plugin 端通过 `args.GetValueOrDefault()` 读取参数，不修改 HTTP 路由或 URL 参数。
**理由**:
- Unity Plugin 的 HTTP 桥接层（`MCPBridgeServer`）已将整个请求 body 反序列化为 `Dictionary<string, object>` 传入命令方法，新增 key 天然透传。
- 无额外路由注册工作。

## Risks / Trade-offs

- **[风险]** `includeTransforms=false` 改变默认行为，现有 LLM prompt 若依赖 `position` 字段会失效
  → **缓解**: 该字段在 hierarchy 中本就低频使用，且 LLM 有 `gameobject_info` 作为 fallback；变更后若发现兼容性问题可回滚为默认 `true`
- **[风险]** `JSON.stringify` 消除后，本地调试时日志可读性下降
  → **缓解**: Server 端可保留 `UNITY_MCP_DEBUG=true` 时 pretty-print，但当前实现无此逻辑；如需可在 `config.js` 中添加 `debugPrettyPrint` 开关（本次不实施）
- **[风险]** Plugin 侧 `MCPSceneCommands.cs` 和 `MCPPrefabAssetCommands.cs` 有两个独立的 `BuildHierarchyNode`，存在代码重复
  → **缓解**: 本次仅同步参数，不重构共用逻辑；未来可考虑提取公共 hierarchy 构建器

## Migration Plan

无需部署或迁移步骤。改动随 submodule 代码更新生效：
1. Plugin 代码修改 → Unity 自动编译 → 重启 Editor 或 domain reload 后生效
2. Server 代码修改 → `npm start` 或 Codex/Claude 重新加载 MCP Server 后生效
3. 回滚：revert 对应文件即可，无数据迁移风险

## Open Questions

- `includeInstanceId` 是否应在未来迭代中改为默认 `false`？需要观察 LLM 对 instanceId 的依赖程度。
- 是否应在 `gameobject_info` 中补充 `tag`/`layer` 的详细输出，以补偿 hierarchy 中的省略？（当前 `gameobject_info` 已包含这些字段）
