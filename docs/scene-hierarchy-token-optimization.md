# scene_hierarchy Token 优化方案

## 背景

`unity_scene_hierarchy` 是 LLM 编辑 Unity 节点树时最常用的工具之一。当前实现在中等规模 prefab（如 TouchControls，137 节点）上产生 ~19K tokens 的响应，其中大量为低价值或可省略的信息。本方案旨在通过序列化层优化将 token 消耗降至 ~4-5K，同时不增加 LLM 的多轮调用负担。

## 现状分析

### Token 消耗实测（TouchControls, 137 节点, tiktoken cl100k_base）

| 字段 | 单节点 tokens | 价值 | 说明 |
|------|-------------|------|------|
| `name` | ~2 | 必需 | 节点标识 |
| `instanceId` | ~2 | 操作必需 | delete / set_transform 等操作需要 |
| `active` | ~2 | 高 | 结构信息 |
| `components` | ~25-40 | 高 | 核心用途——决定节点能做什么 |
| `tag` | ~3 | 低 | 95%+ 节点为 `Untagged` |
| `layer` | ~2 | 低 | UI prefab 几乎全为 `UI` / `Default` |
| `position` | ~12 | 低 | 层级浏览极少需要，按需查 gameobject_info |
| **JSON 结构开销** | ~15 | — | 花括号、引号、逗号 |
| **Pretty print 开销** | ~49 | 零 | `\n  ` 缩进，tiktoken 实测每节点多 49 tokens |

### 单项优化收益估算

| 优化 | 每节点节省 | 137 节点总节省 | 占比 |
|------|-----------|-------------|------|
| 消除 pretty print (`JSON.stringify(data)`) | 49 tok | ~6,700 | 35% |
| 省略 `tag` + `layer` + `position` | 17 tok | ~2,300 | 12% |
| 两者叠加 | 66 tok | ~9,000 | **47%** |
| 137 节点: 19,000 → ~10,000 tokens | | | |

## 优化方案

### 优化 1: 消除 Pretty Print（Server 端）

**文件**: `server/src/tools/editor-tools.js`

**改动**: 所有 `JSON.stringify(data, null, 2)` → `JSON.stringify(data)`

**影响范围**: 全部 ~60 个 tool handler

**收益**: ~35% token 节省

**风险**: 无。MCP 协议传输 JSON 无需可读格式；LLM 解析 compact JSON 和 pretty JSON 的能力完全一致。

**批量改动命令**:
```bash
cd server/src/tools
sed -i '' 's/JSON\.stringify(\(.*\), null, 2)/JSON.stringify(\1)/g' editor-tools.js
# 对其他 tools 文件重复相同操作
```

### 优化 2: 按需输出字段（Plugin 端）

**文件**: `plugin/Editor/MCPSceneCommands.cs`

**改动**: `BuildHierarchyNode()` 新增 `includeTransforms`、`includeTag`、`includeLayer` 参数

**默认行为不变**: 参数默认为 `true`，现有调用者无需修改

**新增参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `includeTransforms` | bool | `false` | 是否输出 `position` 字段 |
| `includeTag` | bool | `false` | 是否输出 `tag` 字段 |
| `includeLayer` | bool | `false` | 是否输出 `layer` 字段 |
| `includeInstanceId` | bool | `true` | 是否输出 `instanceId`（大量场景可省略） |

**建议的新默认值**:

参数从上游的默认值（全部输出）改为新的精简默认值。理由：

- LLM 95% 的 hierarchy 查询目的是"了解结构 + 组件"，不需要 position/tag/layer
- 需要精确位置时，LLM 自然会调用 `gameobject_info` 或 `gameobject_set_transform`
- 这与 `gameobject_info` 形成分层：hierarchy 是"骨架"，info 是"详情"

**实现方案**:

```csharp
public static object GetHierarchy(Dictionary<string, object> args)
{
    // 现有参数
    int maxDepth = args.GetValueOrDefault("maxDepth", 10);
    int maxNodes = args.GetValueOrDefault("maxNodes", 5000);
    string parentPath = args.GetValueOrDefault("parentPath", (string)null);

    // 新增字段控制参数
    bool includeTransforms = args.GetValueOrDefault("includeTransforms", false);
    bool includeTag = args.GetValueOrDefault("includeTag", false);
    bool includeLayer = args.GetValueOrDefault("includeLayer", false);
    bool includeInstanceId = args.GetValueOrDefault("includeInstanceId", true);

    // ... 遍历时传递给 BuildHierarchyNode
}

private static Dictionary<string, object> BuildHierarchyNode(
    GameObject go, int depth, int maxDepth,
    ref int nodeCount, int maxNodes,
    bool includeTransforms, bool includeTag, bool includeLayer, bool includeInstanceId)
{
    // ... 现有逻辑 ...

    var node = new Dictionary<string, object>
    {
        { "name", go.name },
        { "active", go.activeSelf },
        { "components", components },
    };

    if (includeInstanceId)
        node["instanceId"] = go.GetInstanceID();
    if (includeTag)
        node["tag"] = go.tag;
    if (includeLayer)
        node["layer"] = LayerMask.LayerToName(go.layer);
    if (includeTransforms)
        node["position"] = VectorToDict(go.transform.position);

    // ... children 逻辑不变 ...
}
```

### 优化 3: Prefab hierarchy 同步优化（Plugin 端）

**文件**: `plugin/Editor/MCPPrefabAssetCommands.cs`

同样为 `BuildHierarchyNode()` 添加字段控制参数。Prefab 版本额外输出了 `localPosition` / `localRotation` / `localScale`（9 个浮点数），优化收益更大。

新增参数：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `includeTransforms` | bool | `false` | 是否输出 localPosition / localRotation / localScale |

### 优化 4: Server 端参数声明更新

**文件**: `server/src/tools/editor-tools.js`

在 `unity_scene_hierarchy` 的 `inputSchema.properties` 中声明新参数：

```js
{
  name: "unity_scene_hierarchy",
  inputSchema: {
    type: "object",
    properties: {
      maxDepth: { type: "number", description: "Maximum depth to traverse (default: 10)" },
      maxNodes: { type: "number", description: "Maximum total nodes to return (default: 5000)." },
      parentPath: { type: "string", description: "Only return hierarchy under this GameObject path." },
      includeTransforms: { type: "boolean", description: "Include position for each node (default: false). Saves ~12 tokens/node when omitted." },
      includeTag: { type: "boolean", description: "Include tag for each node (default: false)." },
      includeLayer: { type: "boolean", description: "Include layer for each node (default: false)." },
      includeInstanceId: { type: "boolean", description: "Include instanceId for each node (default: true)." },
    },
  },
  handler: async (params) => JSON.stringify(await bridge.getHierarchy(params)),
}
```

## 预期效果

### TouchControls (137 节点)

| 配置 | Tokens | vs 当前 |
|------|--------|---------|
| 当前 (pretty + 全字段) | ~19,000 | baseline |
| 仅消除 pretty | ~12,300 | -35% |
| 仅省略低价值字段 | ~16,700 | -12% |
| **消除 pretty + 省略字段** | **~10,000** | **-47%** |
| 再省 instanceId | ~7,600 | -60% |

### 大型场景 (500 节点)

| 配置 | Tokens |
|------|--------|
| 当前 | ~70,000 |
| 优化后 | ~36,000 |

## 向后兼容

- **新参数默认值**: `includeTransforms=false` 是行为变更。现有 LLM prompt 如果期望 position 字段，需要传 `includeTransforms=true`
- **消除 pretty print**: 纯传输格式变更，对 LLM 解析能力无影响
- **建议迁移策略**: 先实现参数 + 消除 pretty，观察一个迭代周期后再考虑更改默认值

## 本地已有修改（需同步到 submodule）

以下 3 个文件在 `unity-mcp-plugin` 中有本地修改，已同步到 `unity-mcp/plugin/` 但未提交：

| 文件 | 修改内容 |
|------|---------|
| `Editor/MCPEditorCommands.cs` | Roslyn macOS 路径兼容性修复（`TryLoadRoslyn` 追加 `macMonoDir` / `macApiUpdaterDir` 搜索路径 + 诊断日志） |
| `Editor/MCPInstanceRegistry.cs` | 端口范围 7890-7899 → 9000-9009 |
| `Editor/MCPSettingsManager.cs` | 默认端口 7890 → 9000，注释同步更新 |

这些修改应在本方案实施前先提交到 plugin submodule。
