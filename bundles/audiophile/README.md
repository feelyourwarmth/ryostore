# Audiophile

Audio tools and sane controls for people who care how the machine sounds, without turning the base install into a studio image. PipeWire and WirePlumber already ship with Ryoku, so this adds the user-facing toolkit on top: a system-wide effects chain, graphical and terminal patchbays, mixers, low-level PipeWire inspection, and the Bluetooth stack for wireless listening.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| easyeffects | System-wide EQ and effects (parametric EQ, convolver, crossfeed, dynamics) for PipeWire. | pacman | https://github.com/wwmm/easyeffects |
| helvum | GTK patchbay that shows the PipeWire node graph and connects ports by dragging. | pacman | https://gitlab.freedesktop.org/pipewire/helvum |
| qpwgraph | Qt PipeWire graph manager with a patchbay that saves and restores connections. | pacman | https://gitlab.freedesktop.org/rncbc/qpwgraph |
| pavucontrol | GTK volume control for per-app streams, device selection, and card profiles. | pacman | https://freedesktop.org/software/pulseaudio/pavucontrol/ |
| pamixer | Command-line volume mixer for keybindings and scripts. | pacman | https://github.com/cdemoulins/pamixer |
| ncpamixer | ncurses terminal mixer modeled on pavucontrol. | AUR | https://github.com/fulhax/ncpamixer |
| coppwr | Low-level PipeWire control: nodes, clock rate, quantum, metadata, and profiler stats. | AUR | https://github.com/dimtpap/coppwr |
| alsa-utils | ALSA command-line utilities: alsamixer, speaker-test, aplay, and arecord. | pacman | https://www.alsa-project.org |
| bluez | Linux Bluetooth protocol stack daemon for pairing wireless audio devices. | pacman | http://www.bluez.org/ |
| bluez-utils | Bluetooth management utilities including the bluetoothctl client. | pacman | http://www.bluez.org/ |

Install it from **Settings, Extras, Audiophile, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

Routing: ncpamixer and coppwr come from the AUR; everything else from the official repos. PipeWire and WirePlumber already ship with Ryoku.
