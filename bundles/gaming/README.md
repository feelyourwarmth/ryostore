# Gaming

Turns a fresh Ryoku install into a ready-to-play machine: the major launchers, the full Wine and Proton compatibility stack, the GameMode, Gamescope, and MangoHud performance tooling, and a Wayland-friendly Discord client. GPU drivers are left out on purpose, since Ryoku's hardware layer already detects your card and installs the right graphics stack. The bundle enables the [multilib] repository for you, because Steam and the 32-bit helper libraries depend on it.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| steam | Valve game store and client with built-in Proton compatibility. | pacman | https://store.steampowered.com |
| lutris | Open game manager for Windows, native, and emulated games. | pacman | https://lutris.net |
| heroic-games-launcher-bin | Launcher for Epic Games, GOG, and Amazon Prime games. | AUR | https://heroicgameslauncher.com |
| wine | Compatibility layer for running Windows applications on Linux. | pacman | https://www.winehq.org |
| winetricks | Installs runtime libraries and tweaks into Wine prefixes. | pacman | https://github.com/Winetricks/winetricks |
| protontricks | Runs winetricks tasks inside Steam Proton game prefixes. | pacman | https://github.com/Matoking/protontricks |
| protonup-qt | Installs GE-Proton and Wine-GE for Steam, Lutris, and Heroic. | AUR | https://davidotek.github.io/protonup-qt |
| gamemode | Applies temporary performance optimizations while gaming. | pacman | https://github.com/FeralInteractive/gamemode |
| lib32-gamemode | 32-bit GameMode libraries for 32-bit games. | pacman | https://github.com/FeralInteractive/gamemode |
| gamescope | Micro-compositor for upscaling, frame limiting, and isolating games. | pacman | https://github.com/ValveSoftware/gamescope |
| mangohud | Vulkan and OpenGL overlay for FPS, frametimes, and system metrics. | pacman | https://github.com/flightlessmango/MangoHud |
| lib32-mangohud | 32-bit MangoHud libraries for 32-bit games. | pacman | https://github.com/flightlessmango/MangoHud |
| goverlay | GUI to configure MangoHud and vkBasalt without editing config files. | pacman | https://github.com/benjamimgois/goverlay |
| vkbasalt | Vulkan post-processing layer for sharpening, FXAA, SMAA, and deband. | AUR | https://github.com/DadSchoorse/vkBasalt |
| vesktop-bin | Discord client with Vencord and working Wayland screen share. | AUR | https://github.com/Vencord/Vesktop |

Install it from **Settings, Extras, Gaming, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

Routing: heroic-games-launcher-bin, protonup-qt, vkbasalt, and vesktop-bin come from the AUR; the rest from the official repos. The bundle enables [multilib] before installing, since steam and the lib32 libraries live there. GPU drivers are managed by Ryoku's hardware layer, not this bundle.
