---
name: azure-naming
description: Proposes and implements Azure resource names in Terraform - a naming convention, naming.yaml, the LemurDaniel/naming provider or Microsoft's Azure/naming/azurerm module, CAF abbreviations, global unique names, renaming or migrating names. Use when someone asks how to name Azure resources, wants a naming convention ("Namenskonvention", "Ressourcennamen", "naming schema"), or wants hard-coded names in Terraform replaced.
---

# Azure naming

Proposes a naming convention for the Terraform in this repository and implements it with one
mechanism. **A name is rendered by Terraform, never written by you:** you choose patterns and
parameters, `terraform plan` produces the names, the provider or module checks them.

## Outside Claude Code
Codex, Copilot CLI and Gemini CLI load the same skill. Where a step says **ask**, use the
agent's question tool; without one, ask in the chat with numbered options and wait for the
reply. Only a reply that names an option counts.

## Ground rules
- **Terraform only.** A Bicep repository is out of scope: say so and stop.
- **Names are part of the deployed state.** Most Azure resources cannot be renamed: a changed
  name is a destroy and a create. Never let a plan rename a deployed resource without the
  person's explicit yes, resource by resource.
- **One mechanism per configuration.** Never mix the provider and the module in one root.
- **No truncation, no hand-made names.** A name that breaks its type's limit is fixed in the
  pattern or the parameters, never cut and never typed as a literal.
- **Versions are looked up live**, never recalled: the provider from the Terraform Registry
  (`LemurDaniel/naming`), the module from the tags of `Azure/terraform-azurerm-naming`.
- **Customer-facing text** follows the person's language (`en`, `de`).

## Steps

### 1. Detect what the repository has
Search the Terraform roots, read-only:

| Finding | Means |
|---|---|
| `source = "LemurDaniel/naming"`, `data "naming_name"`, a `naming.yaml` | the provider |
| `source = "Azure/naming/azurerm"`, `module.naming.<type>.name` | Microsoft's module |
| locals or an in-house module that build names | a custom mechanism |
| literal `name = "..."` on resources | no mechanism yet |

Also note: the stages (`dev`, `prod`, ...) and regions the roots deploy, whether resources are
already deployed (a state backend, a `terraform.tfstate`, an import block), and the
`hashicorp/azurerm` / `Azure/azapi` versions.

### 2. Ask which mechanism
**Ask** every time, with the detected mechanism first and marked recommended:

1. **LemurDaniel/naming provider** - one `naming.yaml`, every name checked against Azure's rules
   at plan time, `<?PURPOSE>` and `<UNIQUE_ID_3>` for globally unique names.
   [references/provider.md](references/provider.md)
2. **Azure/naming/azurerm module** - Microsoft's module: a slug plus `prefix` / `suffix` lists,
   `name` and `name_unique` per resource type. [references/microsoft-module.md](references/microsoft-module.md)
3. **The repository's own mechanism** - kept as it is, extended in its own style.
   [references/custom.md](references/custom.md)

A switch between mechanisms in a repository with deployed resources is a migration: read
[references/migration.md](references/migration.md) before step 3.

### 3. Propose the convention
Settle the parameters with the person: `location`, `environment` (the stages), `name` (the
workload) and, per resource, the optional `purpose`. Then render the proposal: a scratch root
outside the repository with the mechanism and one name per resource type, `terraform plan`,
and show the names in a table - type, name, length and limit. A name that fails its rule is
reported with the rule, and the pattern or parameter that fixes it is proposed.

**Ask** for sign-off on the table before step 4.

### 4. Implement
Follow the reference of the chosen mechanism: the provider or module block, one name per
resource, every literal name replaced. Deployed resources keep their names (step 5).

### 5. Verify
- `terraform fmt -check`, `terraform validate`, `terraform plan` in every changed root.
- The plan shows **no** `must be replaced` caused by a `name`. Where it does, pin the deployed
  name (see the reference) and plan again; a rename stays only with the person's yes.
- Report the names per stage, what was pinned, and every check that could not run.
