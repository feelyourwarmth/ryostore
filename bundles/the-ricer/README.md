# The Ricer

Eye-candy and theming tools that don't ship with Ryoku by default. One install pulls in a
wallpaper-driven theme maker plus a handful of terminal toys, and adds the Wallhaven frame
popout plugin.

Install it from **Settings → Extras → The Ricer → Install all**, or cherry-pick individual
items. Anything already on the system is detected and **auto-skipped**, so re-running is
safe and only fills the gaps.

## What it installs

| Tool                                              | What it is                              | Upstream                                              |
| ------------------------------------------------- | --------------------------------------- | ---------------------------------------------------- |
| aether                                            | Wallpaper-driven theme maker            | https://github.com/bjarneo/aether                    |
| cbonsai                                           | Grow a bonsai tree in the terminal      | https://gitlab.com/jallbrit/cbonsai                  |
| cmatrix                                           | Matrix rain screensaver                 | https://github.com/abishekvashok/cmatrix             |
| pipes.sh                                          | Animated terminal pipes                 | https://github.com/pipeseroni/pipes.sh               |
| tty-clock                                         | Fullscreen terminal clock               | https://github.com/xorg62/tty-clock                  |
| [wallhaven](../../plugins/wallhaven/README.md)    | Wallhaven frame popout plugin           | Ryoku plugin                                          |

Packages are installed through `ryoku-pkg-add` (pacman + AUR). The wallhaven plugin is a
Ryoku shell plugin: the installer points you at **Settings → Plugins** to add it, since the
shell owns the plugin install path.
