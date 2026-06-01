# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# Output formatting

When presenting content the user will copy-paste verbatim — drafts, emails, Slack messages, ticket descriptions, prose snippets, any text intended for an external destination — output it as plain text without markdown blockquote (`>`) wrapping. The Claude Code CLI renders blockquotes with a `▎` glyph that gets copied along with the text and forces the user to clean it up.

- For prose drafts: plain text, optionally preceded by a short label like `Draft:` or a heading.
- For code, YAML, configs, shell commands: fenced code blocks are fine — they copy cleanly.
- Reserve markdown blockquotes for *quoting back* something the user said, never for content they need to use.
