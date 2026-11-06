# Migrating between mechanisms

A migration changes how names are produced, never what a deployed resource is called. The
goal is a plan with no replacement caused by a name.

## Order

1. **Inventory.** Plan the current state and record every deployed name per root and stage:
   `terraform state list` and `terraform show -json`, or the names the plan shows. The
   inventory is the target the new mechanism must reproduce.
2. **Switch one root at a time.** Add the new mechanism, move each resource's `name` onto
   it, keep the old mechanism until no resource reads it any more, then remove it.
3. **Plan against the inventory.** Every name that differs from its inventory entry is
   pinned (see the mechanism's reference), not accepted. Plan again until no `name` forces a
   replacement.
4. **Ask** for each resource that should be renamed on purpose. A yes is per resource and
   names the replacement it causes.

## Module -> provider

- The module's `name_unique` part is the seed's first characters or a `random_string` in
  state. Read the deployed value from the plan; a provider `<UNIQUE_ID_3>` will not match it,
  so those resources are pinned.
- The module's slugs differ from the provider's abbreviations in places (`kv` both, but not
  every type): compare per type, pin where they differ.
- Lists become parameters: `suffix = [workload, env, region]` maps to `name`, `environment`,
  `location` only where the order of parts matches the pattern.

## Provider -> module

- The module truncates instead of failing, and has no `purpose`. Check that no pinned name
  needs a pattern the lists cannot express; such a resource keeps a literal name with a
  comment.
- The provider's rules check disappears: add a `check` block on the module's
  `validation.<type>.valid_name` for each name.

## Literals -> a mechanism

Every literal is a deployed name until the inventory says otherwise. Pin what exists, apply
the convention to what is new.
