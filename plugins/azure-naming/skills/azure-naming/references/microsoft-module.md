# Microsoft's Azure/naming/azurerm module

Microsoft's naming module ([Azure/terraform-azurerm-naming](https://github.com/Azure/terraform-azurerm-naming)):
one output per azurerm resource type, named after the resource without `azurerm_`
(`azurerm_storage_account` -> `module.naming.storage_account`). Look the version up in the
repository's tags and pin the minor (`~> 0.4.0`); it is still `0.y.z`.

## The root

```hcl
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.0"

  suffix        = [var.workload, var.environment, var.location_short]
  unique-seed   = var.naming_seed      # keep the unique part out of state, see below
  unique-length = 3
}

resource "azurerm_storage_account" "logs" {
  name = module.naming.storage_account.name_unique
}
```

| Input | Meaning |
|---|---|
| `prefix` | list joined before the slug; Microsoft recommends `suffix` instead |
| `suffix` | list joined after the slug: `rg-<suffix...>` |
| `unique-seed` | the unique part, **used literally**: its first `unique-length` characters |
| `unique-length` | length of the unique part, default 4 |
| `unique-include-numbers` | digits in the generated unique part, default true |

Every output carries `name`, `name_unique` (with the unique part), `slug`, `dashes`,
`min_length`, `max_length`, `scope` and `regex`; `module.naming.validation.<type>` holds
`valid_name` and `valid_name_unique`.

## What the module does not do

- **It truncates silently.** `name` is cut to the type's maximum, so two long names can end
  up the same. Check the rendered names' lengths in the plan; shorten the suffix instead of
  relying on the cut.
- **It does not fail on an invalid name.** `validation.<type>.valid_name` is a value, and it
  checks the regex and the minimum, not the maximum. Surface it, e.g. a `check` block per
  name, or the plan stays green on a name Azure rejects.
- **Without `unique-seed` the unique part is a `random_string` in state.** It survives as
  long as the state does; a new state renames every `name_unique`. With `unique-seed` it is
  the seed's first characters (`unique-seed = "verify"`, length 3: `stdataprodwever`) - a
  stable value per stage, not a secret, so choose one that reads like an id. The two
  `random_string` resources are created either way, unused once a seed is set.
- **The slugs are not CAF everywhere** and there is no `purpose`: put the purpose into
  `suffix` (`[var.workload, "logs", var.environment]`) in one fixed position.

## Pinning a deployed name

The module renders from lists, so a deployed name that does not fit them stays a literal on
that one resource, with a comment that it is pinned and why - or the resource moves to the
provider (see [migration.md](migration.md)).
