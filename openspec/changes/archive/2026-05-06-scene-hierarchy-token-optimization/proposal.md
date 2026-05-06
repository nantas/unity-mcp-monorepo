## Why

`unity_scene_hierarchy` 是 LLM 编辑 Unity 场景时最高频调用的工具之一，但当前实现在中等规模 prefab（137 节点）上产生 ~19K tokens 响应，大量消耗在 pretty-print 缩进、以及 LLM 极少需要的 `position`/`tag`/`layer` 等字段上。本方案通过序列化层优化将 token 消耗降低 ~47%，使 LLM 能在单次调用中获得更大的场景视野，减少因 token 超限导致的截断和多轮查询。

## What Changes

- **Server 端**：消除所有 tool handler 中的 `JSON.stringify(data, null, 2)` pretty-print，改为紧凑格式 `JSON.stringify(data)` — 节省 ~35% token 开销
- **Plugin 端 (`MCPSceneCommands.cs`)**：为 `GetHierarchy` / `BuildHierarchyNode` 新增字段控制参数：`includeTransforms` / `includeTag` / `includeLayer` / `includeInstanceId`，默认精简输出（不输出 position/tag/layer）— 节省 ~12% token 开销
- **Plugin 端 (`MCPPrefabAssetCommands.cs`)**：同步为 Prefab asset hierarchy 的 `BuildHierarchyNode` 添加相同的字段控制参数，额外节省 local transform 字段开销
- **Server 端 (`editor-tools.js`)**：在 `unity_scene_hierarchy` 的 `inputSchema.properties` 中声明新增参数，使 LLM 可按需请求完整字段
- 向后兼容：新参数带默认值，不强制现有调用者修改；消除 pretty-print 对 LLM 解析能力无影响

## Capabilities

### New Capabilities
- *(无新增 capability — 本 change 为现有工具的优化)*

### Modified Capabilities
- *(无 spec 级别需求变更 — `openspec/specs/` 为空)*

## Impact

- **Server**: `server/src/tools/editor-tools.js` — 全部 ~60 个 tool handler 的 `JSON.stringify` 调用
- **Plugin**: `plugin/Editor/MCPSceneCommands.cs` — `GetHierarchy` / `BuildHierarchyNode` 方法签名及字段输出逻辑
- **Plugin**: `plugin/Editor/MCPPrefabAssetCommands.cs` — Prefab asset 版本的 `BuildHierarchyNode`
- **通信**: 无协议变更；HTTP 响应体体积减小，降低 `Write EOF` 和 `UNITY_RESPONSE_HARD_LIMIT` 触发概率
- **LLM 行为**: LLM 调用 `unity_scene_hierarchy` 时默认获得更紧凑的 hierarchy；需要精确位置/标签/层级时，显式传入对应参数即可
