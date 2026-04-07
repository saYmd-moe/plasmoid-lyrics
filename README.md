# Plasma Lyrics

A KDE Plasma widget that displays the current song playing from an MPRIS-compatible player together with synchronized lyrics in real time.<br>
This plasmoid is designed to stay lightweight while fitting naturally into a Plasma panel.

## Fork Note

This project started as a fork of [LabyStudio/plasmoid-spotify](https://github.com/LabyStudio/plasmoid-spotify).
Thanks to LabyStudio for building and publishing the original plasmoid that this generalization work builds on.

![Plasma Lyrics Preview](.github/assets/preview.gif)

## Features

- **Generic MPRIS Playback**: Works with the current MPRIS-compatible player instead of only Spotify.
- **Album Artwork**: Displays album art for the currently playing track.
- **Song Details**: Shows the song title and artist name.
- **Song Progress Bar**: A visual indicator of the song's playback progress.
- **Synchronized Lyrics** Animated lyrics scroll in sync with the song progress, powered
  by [lrclib.net](https://lrclib.net).
- **Playback Controls**: Middle-click to play or pause the song.
- **Volume Control**: Adjust volume using the scroll wheel.

## Installation
### Manual Installation
1. **Copy Files**
   Copy the contents of the src folder to your local plasmoid directory:

```bash
mkdir -p ~/.local/share/plasma/plasmoids/plasmoid-lyrics/
cp -r src/* ~/.local/share/plasma/plasmoids/plasmoid-lyrics/
```

2. **Restart Plasmashell**
   To activate the plasmoid, restart the Plasmashell process:

```bash
kquitapp5 plasmashell && kstart5 plasmashell
```

The widget should now be available to add to your KDE Plasma panel or desktop.

## Images
![No Lyrics](.github/assets/no_lyrics.png)
![Desktop Widget](.github/assets/desktop.png)
![Settings](.github/assets/settings.png)

### Inspiration

This project was inspired by:

- [lyrics-on-panel](https://github.com/KangweiZhu/lyrics-on-panel)
- [plasmusic-toolbar](https://github.com/ccatterina/plasmusic-toolbar)
