# Progress

## State (2026-11-06)

- Scaffold: marketplaces (Claude/Copilot, Codex), plugin manifests (Claude, Agent Plugins,
  Gemini), one skill `azure-naming` with references for the provider, Microsoft's module, a
  custom mechanism and migration. Pester checks for the manifests and skills.
- The provider is `LemurDaniel/naming` **2.0.0** (rules check, `<?PURPOSE>`, `<UNIQUE_ID_3>`
  on globally unique types). The examples in `references/provider.md` were planned against
  the released 2.0.0; those in `references/microsoft-module.md` against `Azure/naming/azurerm`
  0.4.4.

## Open

- **License** - not chosen; `claude plugin validate` reports it, the plugin directory
  requires one.
- **Icon** - none yet (512-2048 px square PNG).
- **Evals** - none. First cases: a repo with literal names, a repo on the module, a deployed
  root where a migration must pin names.
- **A run in a real repository**, in Claude Code and in at least one other agent.
- **Provider `convention = "microsoft"`** (in `../terraform-provider-naming`) - renders names
  1:1 like the module, so a migration needs fewer pins. Not started.
- Infrastructure-as-Skills-Azure carries a pre-2.0 copy of the convention
  (`core/iac-rendering/references/naming.default.yaml`, the table in `naming.md`).
