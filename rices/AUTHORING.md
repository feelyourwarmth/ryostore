# Authoring a rice for the Ryoku store

A rice is a whole-desktop look for Ryoku: window decoration and motion, the
shell (bar skin, island, sidebars, frame, roundness, typography), the colour
mode, and an optional wallpaper, launcher hero, and cursor. Users browse,
install, and apply rices from Ryoku Settings, and every apply is reversible in
one click.

## Layout

```
rices/
  registry.json      the catalogue
  <id>/
    rice.json        the manifest (required)
    palette.json     16 wallust colours (required when color is "fixed")
    poster.png       tile art, raw in-repo (recommended)
    screenshots/     gallery images, raw in-repo (optional)
```

Wallpaper and launcher-hero images are large, so they are GitHub Release assets
under the `rices` tag, referenced by absolute URL from the registry, exactly as
livewalls ships its videos. Small text and preview images live in-repo.

## The easy path

Build the look in Ryoku Settings, use Save current setup to make a rice, then:

```
ryoku-hub rice publish <slug> /path/to/ryostore
```

That writes `rices/<slug>/` and upserts the registry entry for you. Upload any
wallpaper or hero as Release assets under the `rices` tag (the command prints
the exact filenames to upload), drop screenshots into `rices/<slug>/screenshots/`,
then commit.

## registry.json entry

| field | meaning |
| --- | --- |
| `id` | folder name and install slug |
| `name`, `author`, `blurb`, `tags` | catalogue copy |
| `createdWith` | the Ryoku version you built on (e.g. `0.6.8`) |
| `color` | `wallpaper` (colours follow the bundled wallpaper) or `fixed` |
| `manifest` | raw path to the rice.json |
| `palette` | raw path to palette.json (fixed colour only) |
| `poster`, `screenshots` | raw in-repo image paths |
| `wallpaper`, `hero` | Release-asset URLs (omit when the rice ships no image) |

`color: wallpaper` gives the most coherent look: the shell, window borders, and
terminal all track the wallpaper's palette. `color: fixed` pins window borders
and the terminal to your palette; ship a wallpaper too so the shell surface
matches.
