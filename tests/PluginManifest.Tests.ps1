# NOTE:
#   Requires: PowerShell 7 and Pester 5+.
#
#   Invoke-Pester -Path ./tests

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester shares BeforeAll variables with the It blocks.')]
param ()

# ===========================================================================
# ===================   CHECK MANIFESTS OF EVERY AGENT   ====================
# ===========================================================================
#
#   same_identity    Claude, Agent Plugins and Gemini name the same plugin,
#                    version and description.
#   agent_plugins    The Agent Plugins manifest has the 1.0.0 schema and no
#                    path fields.
#   marketplaces     Claude and Codex marketplaces point at the plugin.
#   skill_names      There is a skill, and every skill folder has a SKILL.md
#                    whose name is the folder name, plus a description.
#   references       Every reference a SKILL.md links exists.
#   outside_claude   Every SKILL.md explains its question step for other
#                    agents.
#

# The skill cases are built before discovery: -ForEach is evaluated there, before any
# BeforeAll runs, so a list built in BeforeAll would yield no test at all.
BeforeDiscovery {
    $SkillsRoot = Join-Path -Path $PSScriptRoot -ChildPath '../plugins/azure-naming/skills'
    $Skills = @(
        Get-ChildItem -Path $SkillsRoot -Directory
        | ForEach-Object { @{ Folder = $_.Name; Path = Join-Path -Path $_.FullName -ChildPath 'SKILL.md' } }
    )
}

BeforeAll {
    $REPO_ROOT   = Join-Path -Path $PSScriptRoot -ChildPath '..' | Resolve-Path
    $PLUGIN_NAME = 'azure-naming'

    function Read-Json([System.String] $Path) {
        return Get-Content -Path (Join-Path -Path $REPO_ROOT -ChildPath $Path) -Raw | ConvertFrom-Json -AsHashtable
    }

    # '---\nname: x\ndescription: y\n---' => @{ name = 'x'; description = 'y' }
    function Read-Frontmatter([System.String] $Content) {
        $frontmatter = @{}
        if ($Content -match '(?s)^---\r?\n(.*?)\r?\n---') {
            foreach ($line in ($Matches[1] -split '\r?\n')) {
                if ($line -match '^(\w+):\s*(.*)$') {
                    $frontmatter[$Matches[1]] = $Matches[2]
                }
            }
        }
        return $frontmatter
    }

    $Manifests = @{
        claude = Read-Json "plugins/$PLUGIN_NAME/.claude-plugin/plugin.json"
        agents = Read-Json "plugins/$PLUGIN_NAME/plugin.json"
        gemini = Read-Json "plugins/$PLUGIN_NAME/gemini-extension.json"
    }
    $Marketplaces = @{
        claude = Read-Json '.claude-plugin/marketplace.json'
        codex  = Read-Json '.agents/plugins/marketplace.json'
    }
}

Describe 'plugin manifests' {
    It 'same_identity: <Agent> names the plugin, version and description of the Claude manifest' -ForEach @(
        @{ Agent = 'agents' }
        @{ Agent = 'gemini' }
    ) {
        $Manifests.claude.name         | Should -Be $PLUGIN_NAME
        $Manifests[$Agent].name        | Should -Be $PLUGIN_NAME
        $Manifests[$Agent].version     | Should -Be $Manifests.claude.version
        $Manifests[$Agent].description | Should -Be $Manifests.claude.description
    }

    It 'agent_plugins: the Agent Plugins manifest has the 1.0.0 schema and no path fields' {
        $Manifests.agents['$schema'] | Should -Be 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json'
        $Manifests.agents.Keys       | Should -Not -Contain 'skills'
    }

    It 'marketplaces: the Claude marketplace points at the plugin' {
        $entry = $Marketplaces.claude.plugins | Where-Object { $_.name -EQ $PLUGIN_NAME }
        $entry.source | Should -Be "./plugins/$PLUGIN_NAME"
    }

    It 'marketplaces: the Codex marketplace points at the plugin' {
        $entry = $Marketplaces.codex.plugins | Where-Object { $_.name -EQ $PLUGIN_NAME }
        $entry.source.path | Should -Be "./plugins/$PLUGIN_NAME"
    }
}

Describe 'skills' {
    It 'skill_names: the plugin has at least one skill' -ForEach @(@{ Count = $Skills.Count }) {
        $Count | Should -BeGreaterThan 0
    }

    It 'skill_names: <Folder> has its folder name and a description' -ForEach $Skills {
        $frontmatter = Read-Frontmatter (Get-Content -Path $Path -Raw)
        $frontmatter.name        | Should -Be $Folder
        $frontmatter.description | Should -Not -BeNullOrEmpty
    }

    It 'references: every file <Folder> links exists' -ForEach $Skills {
        # '[provider.md](references/provider.md)' => references/provider.md
        $links = [System.Text.RegularExpressions.Regex]::Matches((Get-Content -Path $Path -Raw), '\]\(((?!https?://)[^)#]+)\)')
        | ForEach-Object { $_.Groups[1].Value }

        $links | Should -Not -BeNullOrEmpty
        foreach ($link in $links) {
            Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath $link | Should -Exist
        }
    }

    It 'outside_claude: <Folder> explains its questions for other agents' -ForEach $Skills {
        Get-Content -Path $Path -Raw | Should -Match '## Outside Claude Code'
    }
}
