# The Influencer

A complete stream, record, and edit kit. OBS Studio with Wayland-native game and virtual-camera capture, a full video editor plus fast lossless trimming, image and vector editors for thumbnails, system-wide microphone cleanup, and command-line helpers for generating thumbnails and publishing. Quick clip and instant-replay recording is already covered by the shipped gpu-screen-recorder and wf-recorder, so OBS here is for streaming and advanced multi-source recording.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| obs-studio | Streaming and recording studio with native PipeWire screen and app audio capture. | pacman | https://obsproject.com |
| obs-vkcapture | Vulkan and OpenGL game capture for OBS on Wayland. | AUR | https://github.com/nowrep/obs-vkcapture |
| obs-backgroundremoval | AI webcam background removal for OBS, no green screen needed. | AUR | https://github.com/royshil/obs-backgroundremoval |
| v4l2loopback-dkms | Virtual camera kernel module that powers the OBS Virtual Camera. | pacman | https://github.com/umlaeute/v4l2loopback |
| linux-headers | Kernel headers so DKMS can build the v4l2loopback module. | pacman | https://www.kernel.org |
| kdenlive | Multitrack non-linear video editor with effects, transitions, and keyframes. | pacman | https://apps.kde.org/kdenlive/ |
| losslesscut-bin | Fast lossless trimming, cutting, and merging of video and audio. | AUR | https://github.com/mifi/lossless-cut |
| gimp | Raster image editor for thumbnails, compositing, and retouching. | pacman | https://www.gimp.org/ |
| inkscape | Vector editor for crisp thumbnail text, logos, and overlay assets. | pacman | https://inkscape.org/ |
| krita | Digital painting for illustrated thumbnails and channel art. | pacman | https://krita.org |
| easyeffects | Real-time PipeWire microphone and audio effects chain, system-wide. | pacman | https://github.com/wwmm/easyeffects |
| audacity | Multitrack audio recorder and editor for voiceovers and podcasts. | pacman | https://audacityteam.org |
| capture-website-cli | Renders a URL or HTML file to an image for scripted thumbnails. | npm | https://github.com/sindresorhus/capture-website-cli |
| youtubeuploader | Scripted YouTube uploads from the command line with metadata. | Go | https://github.com/porjo/youtubeuploader |

Install it from **Settings, Extras, The Influencer, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

On Hyprland use the OBS Screen Capture (PipeWire) source, and obs-vkcapture for games (launch them with obs-gamecapture %command%). The OBS Virtual Camera needs the v4l2loopback module, which DKMS builds against linux-headers. Quick clip recording is already covered by the shipped gpu-screen-recorder and wf-recorder.
