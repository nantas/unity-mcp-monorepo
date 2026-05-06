## 1. Documentation

- [x] 1.1 Create `docs/install-workflow.md` with overview, prerequisites, and common clone steps
- [x] 1.2 Write development environment section: symlink plugin to Unity Packages, server npm install, MCP config with placeholders
- [x] 1.3 Write release environment section: run snapshot script, monorepo retention warning, MCP config (same as dev)
- [x] 1.4 Add MCP client configuration templates: `.mcp.json` (Pi/Claude Desktop) and `.codex/config.toml` (Codex CLI)
- [x] 1.5 Add port/multi-instance configuration notes and verification steps
- [x] 1.6 Add troubleshooting section covering symlink permissions and missing npm install

## 2. Snapshot Installation Scripts

- [x] 2.1 Create `scripts/install-plugin.sh` for macOS/Linux with rsync exclusion of `.git`, `.github`, `docs`, `CHANGELOG.md`, `.gitignore`
- [x] 2.2 Ensure `install-plugin.sh` preserves all `.meta` files and explicitly copies `README.md` + its `.meta`
- [x] 2.3 Create `scripts/install-plugin.ps1` for Windows with `Remove-Item` exclusion logic matching the bash script behavior
- [x] 2.4 Ensure `install-plugin.ps1` removes existing target directory before copying and preserves `.meta` files
- [x] 2.5 Add executable permission to `install-plugin.sh` (`chmod +x`)

## 3. Validation

- [x] 3.1 Verify `docs/install-workflow.md` renders correctly in Markdown preview
- [x] 3.2 Dry-run `install-plugin.sh` syntax check with `bash -n`
- [x] 3.3 Dry-run `install-plugin.ps1` syntax validation with PowerShell parser if available
- [x] 3.4 Confirm all `<MONOREPO_ROOT>` and `<UNITY_PROJECT>` placeholders are clearly marked for replacement
