# CLAUDE.md

Guidance for Claude Code in this repository. `PROGRESS.md` holds the state between sessions -
read it first, rewrite it last. `README.md` holds the pitch and the install; neither is
repeated here.

## What This Repo Is

An agent plugin (`azure-naming`) that proposes and implements Azure resource names in
Terraform. One skill asks which mechanism to use - the `LemurDaniel/naming` provider,
Microsoft's `Azure/naming/azurerm` module or the repository's own - and lets Terraform render
every name. The provider lives in `../terraform-provider-naming`; the plugin documents its
interface, it does not copy its convention.

## Commands

```powershell
# Manifests and skills agree (Pester 5).
Invoke-Pester -Path ./tests
Invoke-ScriptAnalyzer -Path ./tests -Severity Warning, Error

# Plugin and marketplace. `claude` is not on PATH on the owner's Windows machine:
# ~/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude.exe
claude plugin validate ./plugins/azure-naming
claude plugin validate .
```

There is no build. The artefacts are Markdown and JSON.

## Constraints

- **No Python, no scripts the plugin depends on.** The engine is Terraform: the provider and
  the module render and check names. A check the model would otherwise do by eye belongs in
  the provider, not in a script here and not in the skill's prose.
- **A name in a skill or reference is one a plan rendered.** Run it (scratch root, released
  provider from the Registry) before writing it down; never derive it by hand.
- **Versions are looked up live, never recalled.** References name the major they describe
  (`~> 2.0`), not a current version.
- **Every agent loads the same skill.** Claude-only tools need the `## Outside Claude Code`
  fallback; the test fails on a `SKILL.md` without it.
- **The three plugin manifests stay identical in name, version and description.** The test
  checks it; a release raises the version in all three.
- **Frontmatter `name` equals the skill's folder name.**
- **Skills carry the rule and its lasting reason, never its history.** Incidents belong in
  the commit message or `PROGRESS.md`.

The `origin` remote URL may embed a GitHub token - never copy a remote URL into a tracked
file, a commit message, or command output you paste back.
