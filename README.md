> [!NOTE]
> **AI Notice:** Parts of this repository (code, fixes and documentation) were created or revised with the help of AI ([Claude Code](https://claude.com/claude-code)). All changes were reviewed by the maintainer.

# Azure Naming 🏷️

Agent skills that propose and implement **Azure resource names in Terraform**, for Claude Code,
GitHub Copilot CLI, OpenAI Codex and Gemini CLI.

A storage account name is not hard because of the syntax. It is hard because it must be 3-24
lowercase characters, unique across all of Azure, follow the convention of everything else,
and never change once deployed: a renamed resource is destroyed and created again. A
language model that writes names by hand gets the shape right and the limits wrong.

This plugin never writes a name itself. It asks which naming mechanism the repository uses,
sets the patterns and parameters, and lets **Terraform render every name** - checked against
Azure's naming rules at plan time, with deployed names pinned so a migration renames nothing.

## Mechanisms

| Mechanism | What the skill does |
|---|---|
| [`LemurDaniel/naming`](https://registry.terraform.io/providers/LemurDaniel/naming) provider | Writes `naming.yaml`, one `data "naming_name"` per resource; every name fails the plan if it breaks its type's rule |
| [`Azure/naming/azurerm`](https://github.com/Azure/terraform-azurerm-naming) module | Microsoft's module with `prefix` / `suffix`; the skill adds the checks the module leaves out (it truncates instead of failing) |
| The repository's own | Keeps it, extends it in its own style, reports names over their limit |

The skill asks which one to use every time, with the one it found in the repository first.

## Install

**Claude Code**
```
/plugin marketplace add LemurDaniel/skills-azure-naming
/plugin install azure-naming@skills-azure-naming
```

**GitHub Copilot CLI** (reads the same marketplace)
```
copilot plugin marketplace add LemurDaniel/skills-azure-naming
copilot plugin install azure-naming@skills-azure-naming
```

**OpenAI Codex**
```
codex plugin marketplace add LemurDaniel/skills-azure-naming
```
Then `/plugins` in `codex` and pick **azure-naming**.

**Gemini CLI** (an extension needs its manifest at the root, so clone first)
```
git clone https://github.com/LemurDaniel/skills-azure-naming
gemini extensions install ./skills-azure-naming/plugins/azure-naming
```

> Built for Claude Code. The manifests for Copilot CLI, Codex and Gemini CLI follow their
> documentation and have not been run in those agents yet.

## Usage

Ask in your words - "how should we name the resources here?", "replace the hard-coded
names with a naming convention", "migrate from Azure/naming/azurerm to the naming provider" -
or call the skill directly (`/azure-naming:azure-naming`, `$azure-naming` in Codex).

## Layout

| Path | Role |
|---|---|
| `plugins/azure-naming/skills/azure-naming/SKILL.md` | The flow: detect, ask the mechanism, propose, implement, verify |
| `plugins/azure-naming/skills/azure-naming/references/` | One file per mechanism, plus migration |
| `plugins/azure-naming/{.claude-plugin/plugin.json,plugin.json,gemini-extension.json}` | Claude, Agent Plugins (Codex) and Gemini manifests |
| `.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json` | Claude/Copilot and Codex marketplaces |
| `tests/` | Pester checks that the manifests and skills agree |

## Status

`0.1.0`, early. The skill flow and the references exist; evals and a run in a real
repository do not yet.
