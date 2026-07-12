# Gaming

Turns a fresh Ryoku install into a **ready-to-play** machine: the major
launchers, the full Wine and Proton compatibility layer, DirectX-to-Vulkan
translation, the GameMode / Gamescope / MangoHud performance stack, broad
controller support, a Wayland-friendly Discord, and a complete lineup of console
emulators. Install it from **Settings, Extras, Gaming, Install all** (core
items); optional items (the emulators and extra tools) install one at a time
from the card. Removing the bundle removes everything it added.

## 32-bit GPU drivers, installed for your hardware (native, no setup)

The base Ryoku install ships **64-bit** graphics drivers. Most games are 32-bit
somewhere (the Steam client, countless titles, and the 32-bit halves of Wine and
Proton prefixes), and without the matching **32-bit (lib32)** GPU userspace they
fall back to slow software rendering or fail to start. This bundle closes that
gap automatically:

- It enables the **[multilib]** repository (where the 32-bit packages live).
- Then Ryoku's hardware layer runs **`ryoku-gpu-lib32`**, which detects every GPU
  in the machine and installs the right 32-bit Vulkan driver on a `lib32-mesa` +
  `lib32-vulkan-icd-loader` baseline: `lib32-vulkan-radeon` for AMD,
  `lib32-vulkan-intel` for Intel, `lib32-nvidia-utils` for NVIDIA. A hybrid
  laptop (Intel iGPU + NVIDIA dGPU) gets both.

That is what lets games run at full hardware capacity out of the box. You never
pick a driver; it follows the card Ryoku already detected. The 64-bit drivers
themselves stay managed by Ryoku's hardware layer, not this bundle.

## Core tools (Install all)

| Tool | What it is | Source |
| --- | --- | --- |
| steam | Valve store and client, with built-in Proton. | pacman |
| lutris | Game manager for Windows, native, and emulated games. | pacman |
| heroic-games-launcher-bin | Epic, GOG, and Amazon Prime launcher. | AUR |
| umu-launcher | Valve's unified Proton runtime for non-Steam games. | pacman |
| wine + winetricks | Windows compatibility layer and prefix helper. | pacman |
| protontricks | winetricks tasks inside Steam Proton prefixes. | pacman |
| protonup-qt | Installs GE-Proton / Wine-GE for Steam, Lutris, Heroic. | AUR |
| vkd3d + lib32-vkd3d | Direct3D 12 to Vulkan translation (Wine/Lutris). | pacman |
| gamemode + lib32-gamemode | Temporary performance tuning while gaming. | pacman |
| gamescope | Upscaling, frame limiting, and per-game isolation. | pacman |
| mangohud + lib32-mangohud | FPS / frametime / system metrics overlay. | pacman |
| goverlay | GUI to configure MangoHud and vkBasalt. | pacman |
| vkbasalt + lib32-vkbasalt | Vulkan post-processing (sharpen, FXAA, SMAA). | AUR |
| game-devices-udev | udev rules for Xbox, PS, Nintendo, 8BitDo pads. | AUR |
| vesktop-bin | Discord with Vencord and working Wayland screen share. | AUR |

## Optional tools (opt-in per item)

**Emulators**, one per system, install one at a time from the card:

| System | Tool | Source |
| --- | --- | --- |
| Multi-system frontend | retroarch (+ libretro-core-info) | pacman |
| SNES / NES / Sega / PS1 / N64 | RetroArch cores: snes9x, mesen, genesis-plus-gx, beetle-psx-hw, mupen64plus-next | pacman |
| GameCube / Wii | dolphin-emu | pacman |
| PlayStation 2 | pcsx2 | AUR |
| PlayStation 3 | rpcs3-bin | AUR |
| PlayStation Portable | ppsspp | pacman |
| Game Boy / GBC / GBA | mgba-qt | pacman |
| Nintendo DS | melonds | AUR |
| Dreamcast | flycast | AUR |
| Wii U | cemu | AUR |
| Original Xbox | xemu | AUR |
| Arcade | mame | pacman |
| Adventure games | scummvm | pacman |
| MS-DOS | dosbox | pacman |

**Extra tools:** corectrl (GPU/CPU tuning and fan curves), antimicrox
(gamepad-to-keyboard mapping), and sc-controller (gamepad profiles).

RetroArch cannot download cores itself on Arch (the online updater is disabled in
the repo build), so install the RetroArch cores you want from the list above;
they appear in RetroArch under **Load Core** immediately.

## Notes

- **Detected and skipped.** Anything already on the system is detected and left
  alone, so re-running only fills the gaps.
- **Routing.** heroic-games-launcher-bin, protonup-qt, vkbasalt, lib32-vkbasalt,
  game-devices-udev, vesktop-bin, and the AUR emulators build from the AUR; the
  rest come from the official repos. steam, umu-launcher, and every `lib32-`
  package live in [multilib], which the bundle enables first.
- **A faster kernel.** For lower latency and higher throughput under load, add
  the **CachyOS Kernel** bundle; it swaps in the performance-tuned kernel and
  keeps the stock one as a fallback.
- **NVIDIA controllers / Wii U / Xbox.** cemu and xemu are AUR builds and can
  lag upstream; if one fails to build, re-run the item after an `AUR` refresh.
- **corectrl** needs the `amdgpu.ppfeaturemask=0xffffffff` kernel parameter for
  full AMD overclock control; without it, monitoring and fan curves still work.
