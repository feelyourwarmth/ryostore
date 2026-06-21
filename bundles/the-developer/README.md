# The Developer

A real workstation for shipping software, not just screenshots. On top of the Neovim, git, github-cli, and language toolchains Ryoku already ships, it adds the Zed editor, a full Docker container stack with terminal dashboards, git diff and database helpers, and the per-project workflow glue (direnv, just) that actual projects depend on.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| zed | GPU-accelerated code editor with language servers and multiplayer. | pacman | https://zed.dev |
| docker | Container engine for building, running, and shipping containers. | pacman | https://www.docker.com/ |
| docker-compose | Docker plugin to run multi-container apps from a compose file. | pacman | https://github.com/docker/compose |
| docker-buildx | Docker plugin for BuildKit multi-platform image builds. | pacman | https://github.com/docker/buildx |
| lazydocker | Terminal UI for Docker containers, images, volumes, and logs. | pacman | https://github.com/jesseduffield/lazydocker |
| git-delta | Syntax-highlighting pager for git, diff, and grep output. | pacman | https://github.com/dandavison/delta |
| gitui | Fast terminal UI for git, written in Rust. | pacman | https://github.com/extrawurst/gitui |
| direnv | Loads and unloads environment variables per directory. | pacman | https://direnv.net |
| just | Command runner for project tasks defined in a justfile. | pacman | https://github.com/casey/just |
| httpie | Human-friendly command-line HTTP and REST client. | pacman | https://github.com/httpie/cli |
| go-yq | Command-line YAML, JSON, and XML processor with jq-style syntax. | pacman | https://github.com/mikefarah/yq |
| lazysql | Terminal UI database client for Postgres, MySQL, SQLite, and more. | Go | https://github.com/jorgerojas26/lazysql |
| ruff | Fast Python linter and code formatter. | pacman | https://github.com/astral-sh/ruff |
| shellcheck | Static analysis linter for shell scripts. | pacman | https://www.shellcheck.net |

Install it from **Settings, Extras, The Developer, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

After installing Docker, enable docker.service and add yourself to the docker group to use it without sudo. go-yq provides the yq command and conflicts with the python yq package, so do not install both. On Arch the Zed binary is zeditor. lazysql installs via go install into ~/.local/bin.
