# Claude plugins to reinstall on the new machine
(installed via marketplaces — reinstall, don't restore binaries)

## known_marketplaces.json
{
  "claude-plugins-official": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-plugins-official"
    },
    "installLocation": "/home/samuel/.claude/plugins/marketplaces/claude-plugins-official",
    "lastUpdated": "2026-06-01T09:16:48.154Z"
  },
  "claude-hud": {
    "source": {
      "source": "github",
      "repo": "jarrodwatts/claude-hud"
    },
    "installLocation": "/home/samuel/.claude/plugins/marketplaces/claude-hud",
    "lastUpdated": "2026-04-21T07:21:07.711Z"
  },
  "datatactics": {
    "source": {
      "source": "directory",
      "path": "/home/samuel/dtacs-repos/skills"
    },
    "installLocation": "/home/samuel/dtacs-repos/skills",
    "lastUpdated": "2026-05-26T09:41:25.259Z"
  }
}
## installed_plugins.json
{
  "version": 2,
  "plugins": {
    "claude-hud@claude-hud": [
      {
        "scope": "user",
        "installPath": "/home/samuel/.claude/plugins/cache/claude-hud/claude-hud/0.1.0",
        "version": "0.1.0",
        "installedAt": "2026-04-21T07:27:26.698Z",
        "lastUpdated": "2026-04-21T07:27:26.698Z",
        "gitCommitSha": "3d9f7b7a78b1c20c049c6fd7500fa180c2d4fe0b"
      }
    ],
    "datatactics-skills@datatactics": [
      {
        "scope": "user",
        "installPath": "/home/samuel/.claude/plugins/cache/datatactics/datatactics-skills/1.5.0",
        "version": "1.5.0",
        "installedAt": "2026-05-26T09:41:44.818Z",
        "lastUpdated": "2026-05-26T09:41:44.818Z",
        "gitCommitSha": "beac745fdd3066e58e15f4db7702606d4fd99325"
      }
    ]
  }
}