import QtQuick 2.15

Item {
    property var utils: null

    readonly property string providerId: "mpris-metadata"

    function fetchNormalizedLyrics(trackName, artistName, albumName, metadata) {
        if (!utils) {
            console.error("MPRIS metadata provider is missing utils");
            return Promise.resolve(null);
        }

        const text = extractLyricsText(metadata);
        if (!text) {
            return Promise.resolve(null);
        }

        const cacheKey = utils.buildLyricsCacheKey(trackName, artistName, albumName);
        return Promise.resolve(utils.createPlainLyricsPayload(text, providerId, cacheKey));
    }

    function extractLyricsText(metadata) {
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

        for (let i = 0; i < candidates.length; i++) {
            const normalized = normalizeLyricsValue(candidates[i]);
            if (normalized) {
                return normalized;
            }
        }

        return "";
    }

    function normalizeLyricsValue(value) {
        if (value === undefined || value === null) {
            return "";
        }

        if (Array.isArray(value)) {
            return value
                .map(entry => normalizeLyricsValue(entry))
                .filter(entry => entry.length > 0)
                .join("\n");
        }

        const text = value.toString().trim();
        return text.length > 0 ? text : "";
    }
}
