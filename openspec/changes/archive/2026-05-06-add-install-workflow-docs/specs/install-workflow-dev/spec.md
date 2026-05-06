## ADDED Requirements

### Requirement: Development environment plugin installation via symlink
The system SHALL allow a developer to install the plugin into a Unity project as a symbolic link, such that modifications to the monorepo plugin directory are immediately reflected in the Unity project.

#### Scenario: macOS/Linux symlink installation
- **WHEN** the developer runs `ln -s <MONOREPO_ROOT>/plugin <UNITY_PROJECT>/Packages/com.anklebreaker.unity-mcp`
- **THEN** the Unity project recognizes the package and loads the plugin from the monorepo path without copying files

#### Scenario: Windows symlink installation
- **WHEN** the developer runs `mklink /D <UNITY_PROJECT>\Packages\com.anklebreaker.unity-mcp <MONOREPO_ROOT>\plugin`
- **THEN** the Unity project recognizes the package and loads the plugin from the monorepo path without copying files

### Requirement: MCP client configuration for development environment
The system SHALL provide MCP client configuration templates that reference the server entry point within the monorepo.

#### Scenario: Pi / Claude Desktop configuration
- **WHEN** the developer copies the `.mcp.json` template and replaces `<MONOREPO_ROOT>` with the actual monorepo absolute path
- **THEN** the MCP client can start the server by executing `node <MONOREPO_ROOT>/server/src/index.js`

#### Scenario: Codex CLI configuration
- **WHEN** the developer copies the `.codex/config.toml` template and replaces `<MONOREPO_ROOT>` with the actual monorepo absolute path
- **THEN** Codex CLI can start the server by executing `node <MONOREPO_ROOT>/server/src/index.js`

### Requirement: Server dependency installation
The system SHALL require `npm install` to be executed in `<MONOREPO_ROOT>/server` before the MCP client can successfully start the server.

#### Scenario: Server startup before npm install
- **WHEN** the MCP client attempts to start the server before `npm install` has been run in the server directory
- **THEN** the server fails to start due to missing `@modelcontextprotocol/sdk` dependency
