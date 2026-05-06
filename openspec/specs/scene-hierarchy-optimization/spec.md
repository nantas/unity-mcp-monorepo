# Scene Hierarchy Token Optimization

## Purpose

Optimize `unity_scene_hierarchy` and related hierarchy tools to reduce token consumption in LLM interactions, enabling larger scene exploration within single API calls.

## ADDED Requirements

### Requirement: Scene hierarchy supports configurable field output
The `unity_scene_hierarchy` tool SHALL support optional parameters to control which per-node fields are included in the response.

#### Scenario: Default compact hierarchy
- **WHEN** `unity_scene_hierarchy` is called without `includeTransforms`, `includeTag`, or `includeLayer`
- **THEN** the response SHALL omit `position`, `tag`, and `layer` fields from each node

#### Scenario: Full hierarchy on demand
- **WHEN** `unity_scene_hierarchy` is called with `includeTransforms: true`, `includeTag: true`, `includeLayer: true`
- **THEN** the response SHALL include `position`, `tag`, and `layer` fields on every node

#### Scenario: InstanceId optional omission
- **WHEN** `unity_scene_hierarchy` is called with `includeInstanceId: false`
- **THEN** the response SHALL omit `instanceId` from each node

### Requirement: Server responses use compact JSON serialization
All tool handlers SHALL serialize response data using compact JSON (`JSON.stringify(data)`) without pretty-print formatting.

#### Scenario: Hierarchy response is compact
- **WHEN** any tool handler returns a JSON response
- **THEN** the response SHALL contain no unnecessary whitespace, indentation, or line breaks added for human readability

### Requirement: Prefab asset hierarchy supports same field controls
The `unity_prefab_asset_hierarchy` tool (or equivalent Prefab asset hierarchy endpoint) SHALL support the same `includeTransforms` parameter with identical default behavior.

#### Scenario: Prefab hierarchy omits transforms by default
- **WHEN** Prefab asset hierarchy is queried without `includeTransforms`
- **THEN** the response SHALL omit `localPosition`, `localRotation`, and `localScale` fields
