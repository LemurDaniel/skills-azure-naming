# The repository's own mechanism

The repository already builds names itself: locals, a naming module of its own, a
`format()` per resource. That mechanism is the convention.

- **Read it before proposing anything.** Find where the name is assembled and which inputs it
  takes; a name not built there is a literal to report.
- **Extend it in its own style.** A new resource type gets its name the way the existing
  ones get theirs - same module, same local, same order of parts. Do not add the provider or
  Microsoft's module beside it: one mechanism per configuration.
- **It has no rules check.** Render the names with `terraform plan` and compare each with its
  type's limit (the Azure naming rules:
  https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules).
  A name over the limit is reported with the limit, not shortened by you.
- **A switch to the provider or the module is a migration** - see [migration.md](migration.md).
