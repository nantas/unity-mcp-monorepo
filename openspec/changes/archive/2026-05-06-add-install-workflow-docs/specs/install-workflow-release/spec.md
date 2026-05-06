## ADDED Requirements

### Requirement: Release environment plugin installation via snapshot copy
The system SHALL provide cross-platform scripts that copy the plugin from the monorepo to a Unity project's `Packages/` directory as a standalone snapshot, excluding development-only files.

#### Scenario: macOS/Linux snapshot installation
- **WHEN** the user runs `scripts/install-plugin.sh <UNITY_PROJECT>` from the monorepo root
- **THEN** the plugin is copied to `<UNITY_PROJECT>/Packages/com.anklebreaker.unity-mcp`
- **AND** `.git/`, `.github/`, `docs/`, `CHANGELOG.md`, and `.gitignore` are excluded
- **AND** all `.meta` files are preserved
- **AND** `README.md` and its `.meta` are preserved

#### Scenario: Windows snapshot installation
- **WHEN** the user runs `scripts/install-plugin.ps1 -UnityProject <UNITY_PROJECT>` from the monorepo root
- **THEN** the plugin is copied to `<UNITY_PROJECT>\Packages\com.anklebreaker.unity-mcp`
- **AND** `.git/`, `.github/`, `docs/`, `CHANGELOG.md`, and `.gitignore` are excluded
- **AND** all `.meta` files are preserved

### Requirement: Monorepo retention in release environment
The system SHALL document that the monorepo directory MUST NOT be deleted after snapshot installation, because the MCP server entry point remains inside `<MONOREPO_ROOT>/server/`.

#### Scenario: User attempts to delete monorepo after release installation
- **WHEN** the user reads the installation workflow documentation for the release environment
- **THEN** a prominent warning clearly states that deleting the monorepo will break the MCP server

### Requirement: MCP client configuration for release environment
The system SHALL provide the same MCP client configuration templates for the release environment as for the development environment, because the server is still launched from the monorepo.

#### Scenario: Release environment MCP client startup
- **WHEN** the user configures `.mcp.json` or `.codex/config.toml` with `<MONOREPO_ROOT>` pointing to the retained monorepo
- **THEN** the MCP client starts the server from `<MONOREPO_ROOT>/server/src/index.js` regardless of whether plugin was installed via symlink or snapshot

### Requirement: Snapshot idempotency
The system SHALL ensure the snapshot installation script can be safely re-run, replacing any existing plugin installation at the target path without leaving stale files.

#### Scenario: Re-running snapshot script after plugin update
- **WHEN** the user pulls updates to the monorepo plugin and re-runs the installation script
- **THEN** the old snapshot at the target path is fully removed
- **AND** a fresh snapshot from the updated monorepo plugin is installed
