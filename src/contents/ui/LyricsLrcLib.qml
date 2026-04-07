import QtQuick 2.15

Item {
    LyricsProviderManager {
        id: lyricsProviderManager
    }

    function fetchLyrics(trackName, artistName, albumName, metadata) {
        return lyricsProviderManager.fetchLyrics(trackName, artistName, albumName, metadata);
    }

    function fetchLyricsPayload(trackName, artistName, albumName, metadata) {
        return lyricsProviderManager.fetchLyricsPayload(trackName, artistName, albumName, metadata);
    }
}
