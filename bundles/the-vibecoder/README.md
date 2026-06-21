# The Vibecoder

The agent-first toolkit for building with AI instead of pretending you do not. The major terminal coding agents from every model vendor, a git-native pair programmer, plus the terminal-flow helpers that keep the agent, logs, tests, and diffs readable in one session. The vendor CLIs install through their own sanctioned installers into ~/.local/bin, no root needed.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| claude-code | Anthropic terminal coding agent that edits code from natural language. | vendor | https://github.com/anthropics/claude-code |
| codex | OpenAI terminal coding agent that reads, edits, and runs code. | npm | https://github.com/openai/codex |
| opencode | Open source terminal coding agent that works across model providers. | npm | https://github.com/sst/opencode |
| gemini-cli | Google open source terminal agent backed by Gemini models. | npm | https://github.com/google-gemini/gemini-cli |
| aider | Terminal pair programmer that edits files in your git repo through chat. | pipx | https://aider.chat |
| zellij | Terminal multiplexer with panes, tabs, layouts, and session resurrection. | pacman | https://zellij.dev |
| glow | Terminal markdown renderer for files, stdin, and URLs. | pacman | https://github.com/charmbracelet/glow |
| git-delta | Syntax-highlighting pager for git diff, show, and blame. | pacman | https://dandavison.github.io/delta/ |
| mods | Sends command output and prompts to a language model and prints markdown. | AUR | https://github.com/charmbracelet/mods |

Install it from **Settings, Extras, The Vibecoder, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

The agent CLIs install through their vendors: Claude Code via its official script, Codex, OpenCode, and Gemini via npm, and aider via pipx, all into ~/.local/bin without root.
