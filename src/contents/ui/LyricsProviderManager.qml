import QtQuick 2.15
import org.kde.plasma.plasmoid
import "providers"

Item {
    property bool enableLrclibProvider: plasmoid.configuration.enableLrclibProvider !== false
    property bool enableMprisMetadataProvider: plasmoid.configuration.enableMprisMetadataProvider !== false

    Utils {
        id: utils
    }

    LrclibProvider {
        id: lrclibProvider
        utils: utils
    }

    MprisMetadataProvider {
        id: mprisMetadataProvider
        utils: utils
    }

    function providers() {
        let chain = [];

        if (enableLrclibProvider) {
            chain.push(lrclibProvider);
        }

        if (enableMprisMetadataProvider) {
            chain.push(mprisMetadataProvider);
        }

        return chain;
    }

    function fetchNormalizedLyrics(trackName, artistName, albumName, metadata) {
        return fetchFromProvider(0, trackName, artistName, albumName, metadata);
    }

    function fetchLyricsPayload(trackName, artistName, albumName, metadata) {
        return fetchNormalizedLyrics(trackName, artistName, albumName, metadata);
    }

    function fetchLyrics(trackName, artistName, albumName, metadata) {
        return fetchNormalizedLyrics(trackName, artistName, albumName, metadata)
            .then(payload => payload ? payload.lines : null);
    }

    function fetchFromProvider(index, trackName, artistName, albumName, metadata) {
        const chain = providers();
        if (index >= chain.length) {
            return Promise.resolve(null);
        }

        const provider = chain[index];
        if (!provider || !provider.fetchNormalizedLyrics) {
            return fetchFromProvider(index + 1, trackName, artistName, albumName, metadata);
        }

        return provider.fetchNormalizedLyrics(trackName, artistName, albumName, metadata)
            .then(payload => {
                if (payload) {
                    return payload;
                }
                return fetchFromProvider(index + 1, trackName, artistName, albumName, metadata);
            })
            .catch(error => {
                console.warn("Lyrics provider failed:", provider.providerId || index, error);
                return fetchFromProvider(index + 1, trackName, artistName, albumName, metadata);
            });
    }
}
