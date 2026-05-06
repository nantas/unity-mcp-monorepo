## 1. Server 端全局消除 Pretty Print

- [x] 1.1 `server/src/tools/editor-tools.js`：将所有 `JSON.stringify(..., null, 2)` 替换为 `JSON.stringify(...)`
- [x] 1.2 检查 `server/src/tools/` 下其他 tools 文件（`hub-tools.js` / `instance-tools.js` / `context-tools.js` / `uma-tools.js`）是否存在相同模式，一并替换

## 2. Plugin Scene Hierarchy 字段控制

- [x] 2.1 `plugin/Editor/MCPSceneCommands.cs` — `GetHierarchy()` 方法：从 `args` 读取 `includeTransforms`/`includeTag`/`includeLayer`/`includeInstanceId`（默认 `false`/`false`/`false`/`true`）
- [x] 2.2 `plugin/Editor/MCPSceneCommands.cs` — 修改 `BuildHierarchyNode()` 方法签名，追加 4 个 `bool` 参数字段控制
- [x] 2.3 `plugin/Editor/MCPSceneCommands.cs` — 在 `BuildHierarchyNode()` 内，根据参数条件添加 `instanceId`/`tag`/`layer`/`position` 字段
- [x] 2.4 `plugin/Editor/MCPSceneCommands.cs` — 更新递归调用 `BuildHierarchyNode(...)` 以透传新参数

## 3. Plugin Prefab Asset Hierarchy 字段控制同步

- [x] 3.1 `plugin/Editor/MCPPrefabAssetCommands.cs` — 找到调用 `BuildHierarchyNode()` 的位置（约第 35 行），从 `args` 读取 `includeTransforms`
- [x] 3.2 `plugin/Editor/MCPPrefabAssetCommands.cs` — 修改 Prefab 版本 `BuildHierarchyNode()` 方法签名，追加 `bool includeTransforms` 参数
- [x] 3.3 `plugin/Editor/MCPPrefabAssetCommands.cs` — 在 Prefab 版本 `BuildHierarchyNode()` 内，条件添加 `localPosition`/`localRotation`/`localScale` 字段
- [x] 3.4 `plugin/Editor/MCPPrefabAssetCommands.cs` — 更新递归调用以透传 `includeTransforms`

## 4. Server 端 Tool Schema 声明更新

- [x] 4.1 `server/src/tools/editor-tools.js` — 在 `unity_scene_hierarchy` 的 `inputSchema.properties` 中追加 `includeTransforms`/`includeTag`/`includeLayer`/`includeInstanceId` 参数定义及 description
- [x] 4.2 `server/src/tools/editor-tools.js` — 将 `unity_scene_hierarchy` handler 中的 `JSON.stringify(..., null, 2)` 替换为紧凑格式（可与 1.1 合并执行）

## 5. 验证与提交

- [ ] 5.1 Plugin：确认 Unity Editor 编译无错误（`MCPSceneCommands.cs` + `MCPPrefabAssetCommands.cs`）
- [ ] 5.2 按 monorepo 铁律提交：先进入 `plugin/` 子模块 commit & push，再进入 `server/` 子模块 commit & push，最后在 monorepo 提交指针更新 + openspec change
