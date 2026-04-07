import QtQuick 2.15
import org.kde.plasma.plasmoid
import "providers"

Item {
    property bool enableLrclibProvider: plasmoid.configuration.enableLrclibProvider !== false
    property bool enableMprisMetadataProvider: plasmoid.configuration.enableMprisMetadataProvider !== false
    property var payloadCache: ({})
    property var inflightRequests: ({})

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
        const requestKey = buildRequestKey(trackName, artistName, albumName, metadata);

        if (payloadCache[requestKey] !== undefined) {
            return Promise.resolve(payloadCache[requestKey]);
        }

        if (inflightRequests[requestKey] !== undefined) {
            return inflightRequests[requestKey];
        }

        const request = fetchFromProvider(0, trackName, artistName, albumName, metadata)
            .then(payload => {
                if (payload) {
                    payloadCache[requestKey] = payload;
                }

                delete inflightRequests[requestKey];
                return payload;
            })
            .catch(error => {
                delete inflightRequests[requestKey];
                throw error;
            });

        inflightRequests[requestKey] = request;
        return request;
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

    function buildRequestKey(trackName, artistName, albumName, metadata) {
        return [
            providerSignature(),
            utils.buildLyricsCacheKey(trackName, artistName, albumName),
            metadataSignature(metadata)
        ].join("||");
    }

    function providerSignature() {
        return [
            enableLrclibProvider ? "lrclib:on" : "lrclib:off",
            enableMprisMetadataProvider ? "mpris:on" : "mpris:off"
        ].join("|");
    }

    function metadataSignature(metadata) {
        if (!metadata) {
            return "";
        }

        const candidates = [
            metadata["xesam:asText"],
            metadata["asText"],
            metadata.asText,
            metadata.lyrics,
            metadata["xesam:lyrics"]
        ];

        return candidates
            .map(value => {
                if (value === undefined || value === null) {
                    return "";
                }

                if (Array.isArray(value)) {
                    return value.join("\n");
                }

                return value.toString();
            })
            .join("|");
    }
}
