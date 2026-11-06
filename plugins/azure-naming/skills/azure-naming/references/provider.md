# The LemurDaniel/naming provider

A Terraform provider that renders names from one YAML convention at plan time and checks each
one against its resource type's naming rule. No module, nothing in state.
Registry: `registry.terraform.io/providers/LemurDaniel/naming`. This file describes the 2.x
interface; look the current version up in the Registry and pin `~> <major>.0`.

## The root

```hcl
terraform {
  required_providers {
    naming = {
      source  = "LemurDaniel/naming"
      version = "~> 2.0"
    }
  }
}

provider "naming" {
  convention  = "default"
  naming      = "${path.module}/naming.yaml"
  random_seed = var.naming_seed        # one per stage, never changed once deployed

  parameters = {
    location    = var.location
    environment = var.environment
    name        = var.workload
  }
}

data "naming_name" "storage_account" {
  resource   = "Azure::Microsoft.Storage/storageAccounts"
  parameters = { purpose = "logs" }    # optional, per call
}

resource "azurerm_storage_account" "logs" {
  name = data.naming_name.storage_account.name
}
```

- `resource` is `Azure::<ARM type>[::<kind>]`, e.g. `Azure::Microsoft.Compute/disks::os`, a
  Windows VM `Azure::Microsoft.Compute/virtualMachines::windows`.
- `index = { start, count }` renders several names (`at_index`); `count` is how many.
- `data "naming_schema"` returns the resolved abbreviations, patterns, mappings and rules.

## The convention

The bundled `default` follows CAF abbreviations and AVM region codes:

| Kind of name | Pattern |
|---|---|
| most types | `<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME><?PURPOSE;-%s>-<INDEX;%02s>` |
| unique across Azure (storage, key vault, registry, App Service, SQL, Redis, Service Bus, ...) | `...-<NAME><?PURPOSE;-%s>-<UNIQUE_ID_3>`, without hyphens where the type allows none |
| no hyphens allowed (storage, registry, batch, ...) | `<TYPE><LOCATION><ENVIRONMENT><NAME><?PURPOSE>...` |

`<UNIQUE_ID_3>` comes from `random_seed`; without a seed a globally unique name fails the
plan. A second instance of a global type differs in `name` or `purpose`, not in an index.

**`naming.yaml` is a full copy of the convention**, written beside the root on the first run
and owned by the repository from then on. A copy, not a three-line override: an upgrade of
the provider must never change a deployed name. Take it from the provider's
`examples/basic/naming.full.yaml` of the pinned version, or build it from `naming_schema`.
A departure (an abbreviation, a pattern, a stage) goes into this file, never into a literal.

## Naming rules

Every rendered name is checked against its type's rule (length, characters, scope), taken
from Microsoft's `Azure/naming/azurerm` definitions and corrected where they contradict the
Azure documentation. `validation = "error"` (default) fails the plan, `"warn"` reports.
Never set `warn` or `off` to make a plan pass: fix the pattern. A rule the repository needs
differently goes under `rules:` in `naming.yaml`:

```yaml
rules:
  Azure:
    Microsoft.Storage/storageAccounts:
      max_length: 20
```

## Pinning a deployed name

A deployed resource whose name the convention would change keeps its name through a pattern
in `naming.yaml` that renders it, for that resource only (a `naming_id`):

```yaml
patterns:
  Azure:
    Microsoft.Storage/storageAccounts:
      legacy_logs: "<TYPE><ENVIRONMENT><NAME>logs01"   # name = "data": stproddatalogs01
```

```hcl
data "naming_name" "legacy_logs" {
  resource  = "Azure::Microsoft.Storage/storageAccounts"
  naming_id = "legacy_logs"
}
```

Confirm with `terraform plan` that the resource shows no replacement.
