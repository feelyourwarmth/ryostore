# Writing a Nautilus script pack

A pack is a set of right-click file-manager actions a bundle can install. It
ships as plain executable scripts that land in
`~/.local/share/nautilus/scripts/<subdir>/`, where Nautilus rescans them live
(no rebuild, no extension). Removing the pack deletes that subdir. This is the
lowest-friction guest: install, right-click, use; remove, gone.

## Layout

```
nautilus/<id>/
  manifest.json      id, name, version, author, description, subdir, scripts[]
  scripts/           the executable files, one per action
    Reformat 9x16 (crop)
    Transcode to H.264
    ...
  README.md          what the actions do
```

## `manifest.json`

```jsonc
{
  "id": "video-reformat",
  "name": "Video Reformat",
  "version": "0.1.0",
  "author": "Ryoku <releases@ryoku.dev>",
  "description": "Right-click video reformat, transcode, and caption tools.",
  "subdir": "Ryoku Creator",          // scripts land in scripts/<subdir>/ (the submenu name)
  "scripts": [                         // files under scripts/, installed 0755
    "Reformat 9x16 (crop)",
    "Transcode to H.264"
  ]
}
```

`ryoku-hub extras nautilus <id>` fetches `scripts/<each>` into
`~/.local/share/nautilus/scripts/<subdir>/` (mode 0755) and records the file
list under `~/.local/share/ryoku/nautilus/<id>/` so removal is exact.

## Writing a script

Nautilus exports `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` (one absolute path per
line; empty for remote/smb selections). Loop it safely and report with
`notify-send`:

```bash
#!/usr/bin/env bash
# Reformat selected videos to 9:16, cropped to fill.
set -euo pipefail
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "${f,,}" in *.mp4|*.mov|*.mkv|*.webm) ;; *) continue ;; esac
  out="${f%.*}_9x16.mp4"
  ffmpeg -y -i "$f" -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1" -c:a copy "$out" \
    && notify-send -a "Ryoku Creator" "Reformatted" "$(basename "$out")"
done <<< "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
```

`ffmpeg`, `magick` (ImageMagick), `slurp`, `grim`, `zenity`, and `jq` are
guaranteed by the base desktop; anything else the pack needs must be a bundle
`package`/`script` item so it is installed alongside.

## List it

Add an object to `nautilus/registry.json` so bundles can reference it:

```jsonc
{ "id": "video-reformat", "name": "Video Reformat",
  "path": "nautilus/video-reformat", "version": "0.1.0", "author": "Ryoku",
  "official": true, "subdir": "Ryoku Creator",
  "description": "Right-click video reformat, transcode, and caption tools." }
```

A bundle installs the pack with an item `{ "type": "nautilus-pack", "name": "video-reformat" }`.
