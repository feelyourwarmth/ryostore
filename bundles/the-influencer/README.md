# The Influencer

A complete **stream, record, edit, reformat, and publish** kit: a
curated set of recording, editing, audio, and thumbnail tools, plus a
**right-click video toolkit** in the file manager that ships with the bundle and
needs no setup. Install it from **Settings, Extras, The Influencer, Install all**
(core items); optional items install one at a time from the card. Removing the
bundle removes everything it added.

## The right-click video toolkit (shipped from ryostore, no setup)

**Video Reformat** is a Nautilus script pack: it adds a **Scripts, Ryoku Creator**
menu to the file manager. Select one or more clips, right-click, and pick an
action. It runs on `ffmpeg`, installed by the bundle:

- **Reformat** to 9:16, 1:1, or 16:9 (crop or pad) for Reels, TikTok, and Shorts.
- **Transcode** to H.264 or H.265, or **Transcode for DaVinci (DNxHR)** so the
  free Resolve build can import your footage.
- **Compress to 8 MiB** (Discord-safe), **Make GIF**, **Extract audio (MP3)**.
- **Generate captions (SRT)** with local, offline speech-to-text, if you install
  a `whisper.cpp` build yourself. No Arch or AUR package provides one, so the
  bundle does not ship it and this action stays inert until you do.
- **Strip metadata**, **Grab thumbnail**.

See `nautilus/video-reformat/README.md`.

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
cannot import H.264/H.265 + AAC, so run the **Transcode for DaVinci (DNxHR)**
right-click action on your clips first.

## Notes

- **Kernel headers:** `v4l2loopback-dkms` builds against the running kernel's
  headers. Ryoku ships the CachyOS kernel, so if the DKMS build fails install
  `linux-cachyos-headers` (or the headers matching your kernel) and re-run.
- **NVIDIA on Wayland:** OBS NVENC and PipeWire capture want driver 555+.
- Quick clip and instant-replay recording are covered by the shipped
  gpu-screen-recorder and Ryoku's record controls; OBS here is for streaming and
  multi-source recording.
