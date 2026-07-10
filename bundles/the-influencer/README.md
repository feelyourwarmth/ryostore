# The Influencer

A complete **stream, record, edit, reformat, caption, and publish** kit, plus
two guests that live in the desktop: a **Creator Deck** in the left sidebar and
a **Video Reformat** right-click menu in the file manager. Install it from
**Settings, Extras, The Influencer, Install all** (core items); optional items
install one at a time from the card.

## The guests (shipped from ryoku-extras, no setup)

- **Creator Deck** (`sidebarLeft` plugin) mounts as a tab in the left sidebar
  (`SUPER+D`): go live / launch an editor, set the aspect target, reformat or
  caption the last recording, mute the mic, toggle EasyEffects, watch disk
  headroom, and reveal recent clips. Auto-enabled on install.
- **Video Reformat** (Nautilus script pack) adds a **Scripts, Ryoku Creator**
  right-click menu: reformat to 9:16 / 1:1 / 16:9, transcode, compress to a
  size, extract audio, make a GIF, strip metadata, grab a thumbnail, and
  transcode for DaVinci. See `nautilus/video-reformat/README.md`.

## Core tools

| Tool | What it is | Source |
| --- | --- | --- |
| obs-studio | Streaming and recording studio (PipeWire capture). | pacman |
| obs-vkcapture | Vulkan/OpenGL game capture on Wayland. | AUR |
| obs-backgroundremoval | AI webcam background removal. | AUR |
| obs-pipewire-audio-capture | Per-application audio capture. | AUR |
| v4l2loopback-dkms + linux-headers | Virtual camera module (see kernel note). | pacman |
| gpu-screen-recorder | GPU-encoded recorder + replay buffer. | pacman |
| wf-recorder | Lightweight wlroots recorder. | pacman |
| kdenlive | Multitrack video editor. | pacman |
| losslesscut-bin | Fast lossless trim/cut/merge. | AUR |
| easyeffects + noise-suppression-for-voice | Mic FX chain + RNNoise. | pacman |
| audacity | Multitrack audio editor. | pacman |
| gimp / inkscape / krita | Thumbnails, vectors, channel art. | pacman |
| yt-dlp | Download reference footage / audio. | pacman |
| handbrake | Batch transcoder with presets. | pacman |
| whisper.cpp | Local speech-to-text for captions. | AUR |
| capture-website-cli | Render a URL to a thumbnail image. | npm |
| youtubeuploader | Scripted YouTube uploads. | Go |

## Optional tools (opt-in per item)

DaVinci Resolve (interactive fetch, see below), REAPER (paid DAW), wl-screenrec,
DistroAV (NDI), Owncast, Shotcut, Blender, Darktable, Upscayl, QPrompt, and
Subtitle Edit.

## DaVinci Resolve

Resolve is proprietary; its licence forbids redistribution, so it cannot be
bundled. Selecting it opens the Blackmagic download page, waits for you to save
the installer `.zip`, then builds the AUR package. The **free** Linux build
cannot import H.264/H.265 + AAC, so run the Creator **Transcode for DaVinci
(DNxHR)** right-click action on your clips first.

## Notes

- **Kernel headers:** `v4l2loopback-dkms` builds against the running kernel's
  headers. Ryoku ships the CachyOS kernel, so if the DKMS build fails install
  `linux-cachyos-headers` (or the headers matching your kernel) and re-run.
- **NVIDIA on Wayland:** OBS NVENC and PipeWire capture want driver 555+.
- Quick clip and instant-replay recording are covered by the shipped
  gpu-screen-recorder and the right sidebar; OBS here is for streaming and
  multi-source recording.
