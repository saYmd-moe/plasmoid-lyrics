import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore
import "Localizer.js" as L10n

PlasmoidItem {
    id: widget

    Plasmoid.status: playerAdapter.ready ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: plasmoid.configuration.transparentBackground
        ? PlasmaCore.Types.NoBackground
        : PlasmaCore.Types.DefaultBackground

    Layout.preferredWidth: row.implicitWidth
    Layout.preferredHeight: row.implicitHeight

    readonly property int volumeStep: 2
    property int lyricsRequestToken: 0
    property bool lyricsLoading: false
    property bool instrumentalHint: false
    property int tapCount: 0
    readonly property string lyricsStatusText: buildLyricsStatusText()
    readonly property string tooltipMainText: buildTooltipMainText()
    readonly property string tooltipSubText: buildTooltipSubText()


    /* Lyrics LRC library */
    LyricsLrcLib {
        id: lyricsLrcLib
    }

    /* Current MPRIS player */
    PlayerAdapter {
        id: playerAdapter
    }

    /* Signal handlers */
    Connections {
        target: playerAdapter

        onReadyChanged: {
            if (!playerAdapter.ready) {
                lyricsLoading = false
                lyricsRenderer.lyricsPayload = null
            } else {
                updateArtwork()
                Qt.callLater(updateLyrics)
            }
        }

        onPositionChanged: {
            if (playerAdapter.ready) {
                updateProgressIndicator()
            }
        }

        onArtworkUrlChanged: updateArtwork()
        onIdentityChanged: Qt.callLater(updateLyrics)
        onTrackChanged: Qt.callLater(updateLyrics)
        onArtistChanged: Qt.callLater(updateLyrics)
        onAlbumChanged: Qt.callLater(updateLyrics)
    }

    /* Progress bar updater */
    Timer {
        id: timer
        interval: 1000;
        running: playerAdapter && playerAdapter.playing;
        repeat: true
        onTriggered: () => {
            updateProgressIndicator()
        }
    }

    Timer {
        id: tapSequenceTimer
        interval: 280
        repeat: false
        onTriggered: {
            handleTapSequence(tapCount)
            tapCount = 0
        }
    }

    /* Hover handling */
    MouseArea {
        z: 99
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: playerAdapter && playerAdapter.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        active: tooltipMainText.length > 0
        mainText: tooltipMainText
        subText: tooltipSubText
    }

    MouseArea {
        z: 100
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: false

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton || mouse.button === Qt.MiddleButton) {
                tapCount = Math.min(3, tapCount + 1)
                tapSequenceTimer.restart()
            }
        }
    }

    WheelHandler {
        onWheel: (eventPoint, event) => {
            if (event.angleDelta.y > 0) {
                playerAdapter.changeVolume(volumeStep / 100, true)
            } else {
                playerAdapter.changeVolume(-volumeStep / 100, true)
            }
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0
        clip: true

        LyricsRenderer {
            id: lyricsRenderer
            lyricsPayload: null
            playerAdapter: playerAdapter
            loading: lyricsLoading
            instrumentalHint: instrumentalHint
            visible: plasmoid.configuration.showLyrics && playerAdapter && playerAdapter.ready
            Layout.fillWidth: true
            centeredLyrics: !plasmoid.configuration.showAlbumCover
                && !plasmoid.configuration.showTitle
                && !plasmoid.configuration.showArtist
        }

        /* Album artwork */
        Image {
            id: artwork

            Layout.preferredWidth: parent.height
            Layout.preferredHeight: parent.height
            Layout.rightMargin: 5
            Layout.fillWidth: false
            fillMode: Image.PreserveAspectFit


            property string fallbackSource: "../assets/icon.svg"
            property string lastAttemptedSource: ""

            source: artwork.fallbackSource
            visible: plasmoid.configuration.showAlbumCover

            Timer {
                id: fallbackTimer
                interval: 5000
                repeat: false
                onTriggered: {
                    console.warn("Failed to load artwork from", artwork.lastAttemptedSource)
                    artwork.source = artwork.fallbackSource
                }
            }

            onSourceChanged: {
                if (source === fallbackSource) {
                    fallbackTimer.stop()
                } else {
                    fallbackTimer.restart()
                    lastAttemptedSource = source
                }
            }

            onStatusChanged: {
                switch (status) {
                    case Image.Ready:
                        fallbackTimer.stop()
                        break
                }
            }

            /* Border radius */
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: artwork.width
                    height: artwork.height
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                    }
                }
            }

            /* Progress bar */
            Rectangle {
                id: progress
                visible: playerAdapter && playerAdapter.ready

                x: 2
                height: 3
                width: artwork.width - 4
                anchors.bottom: parent.bottom
                color: "#282828"

                Rectangle {
                    id: progressIndicator
                    anchors.bottom: parent.bottom
                    height: 2
                    width: 0
                    color: "#1db954"
                }
            }
        }

        /* Song information */
        Item {
            Layout.preferredWidth: column.implicitWidth
            Layout.preferredHeight: column.implicitHeight
            Layout.fillWidth: true
            visible: plasmoid.configuration.showTitle || plasmoid.configuration.showArtist

            ColumnLayout {
                id: column
                anchors.fill: parent
                spacing: 0

                /* Song title */
                Text {
                    id: title
                    wrapMode: Text.NoWrap
                    lineHeightMode: Text.FixedHeight
                    Layout.fillWidth: true
                    Layout.rightMargin: 20

                    color: plasmoid.configuration.useCustomTitleColor ? plasmoid.configuration.titleTextColor : Kirigami.Theme.textColor
                    font.pixelSize: plasmoid.configuration.titleFontSize
                    font.family: plasmoid.configuration.titleFontFamily
                    font.weight: Font.Bold
                    text: playerAdapter && playerAdapter.ready
                        ? truncateTrackText(playerAdapter.track, plasmoid.configuration.maxTitleArtistLength)
                        : L10n.tr("Lyrics", "歌词")

                    Layout.preferredHeight: title.font.pixelSize + 4
                    visible: plasmoid.configuration.showTitle
                }

                /* Artist name */
                Text {
                    id: artist
                    wrapMode: Text.NoWrap
                    lineHeightMode: Text.FixedHeight
                    Layout.fillWidth: true
                    Layout.rightMargin: 20

                    color: plasmoid.configuration.useCustomArtistColor ? plasmoid.configuration.artistTextColor : Kirigami.Theme.textColor
                    font.pixelSize: plasmoid.configuration.artistFontSize
                    font.family: plasmoid.configuration.artistFontFamily
                    text: playerAdapter && playerAdapter.ready
                        ? truncateText(playerAdapter.artist, plasmoid.configuration.maxTitleArtistLength)
                        : L10n.tr("No song playing", "当前没有播放")

                    Layout.preferredHeight: artist.font.pixelSize + 4
                    visible: plasmoid.configuration.showArtist
                }
            }
        }
    }

    function updateProgressIndicator() {
        if (playerAdapter.ready) {
            progressIndicator.width = Math.min(1, (playerAdapter.getDaemonPosition() / playerAdapter.length)) * progress.width
        }
    }

    function truncateText(text, maxLen) {
        return text && text.length > maxLen
            ? text.slice(0, maxLen - 3) + "..."
            : text;
    }

    function truncateTrackText(text, maxLen) {
        if (!text || text.length <= maxLen) {
            return text;
        }

        const separators = [" - ", " – ", " — ", ": ", " (", " [", " / "];
        for (let i = 0; i < separators.length; i++) {
            const index = text.indexOf(separators[i]);
            if (index > 12 && index <= maxLen) {
                return text.slice(0, index) + "...";
            }
        }

        return truncateText(text, maxLen);
    }

    function isInstrumentalTrack(track, artist, album, metadata) {
        const fields = [
            track || "",
            artist || "",
            album || "",
            metadata && metadata["xesam:title"] ? metadata["xesam:title"] : "",
            metadata && metadata["xesam:comment"] ? metadata["xesam:comment"] : ""
        ].join(" ").toLowerCase();

        const hints = [
            "instrumental",
            "inst.",
            "karaoke",
            "伴奏",
            "纯音乐",
            "演奏曲",
            "音乐版"
        ];

        for (let i = 0; i < hints.length; i++) {
            if (fields.indexOf(hints[i]) >= 0) {
                return true;
            }
        }

        return false;
    }

    function buildLyricsStatusText() {
        if (!playerAdapter || !playerAdapter.ready) {
            return L10n.tr("Player: not ready", "播放器：未就绪");
        }

        const details = [
            L10n.tr("Player: ", "播放器：") + (playerAdapter.identity || L10n.tr("Unknown", "未知")),
            L10n.tr("Track: ", "曲目：") + (playerAdapter.track || L10n.tr("Unknown", "未知")),
            L10n.tr("Artist: ", "艺术家：") + (playerAdapter.artist || L10n.tr("Unknown", "未知"))
        ];

        if (lyricsLoading) {
            details.push(L10n.tr("Lyrics: looking up", "歌词：正在查找"));
            details.push(L10n.tr("Enabled providers: LRCLIB, MPRIS metadata", "已启用来源：LRCLIB、MPRIS 元数据"));
            return details.join("\n");
        }

        if (lyricsRenderer.lyricsPayload) {
            details.push(L10n.tr("Lyrics source: ", "歌词来源：") + formatLyricsSource(lyricsRenderer.lyricsPayload.source));
            details.push(L10n.tr("Lyrics mode: ", "歌词模式：") + L10n.lyricsMode(lyricsRenderer.lyricsPayload.mode));
        } else {
            details.push(L10n.tr("Lyrics: unavailable", "歌词：不可用"));
            details.push(L10n.tr("Enabled providers: LRCLIB, MPRIS metadata", "已启用来源：LRCLIB、MPRIS 元数据"));
        }

        return details.join("\n");
    }

    function buildTooltipMainText() {
        if (!playerAdapter || !playerAdapter.ready) {
            return L10n.tr("Plasma Lyrics", "Plasma 歌词");
        }

        if (playerAdapter.track && playerAdapter.artist) {
            return playerAdapter.track + "\n" + playerAdapter.artist;
        }

        return playerAdapter.track || playerAdapter.artist || L10n.tr("Plasma Lyrics", "Plasma 歌词");
    }

    function buildTooltipSubText() {
        if (!playerAdapter || !playerAdapter.ready) {
            return L10n.tr("Waiting for a compatible player.", "等待兼容的播放器。");
        }

        return buildLyricsStatusText();
    }

    function handleTapSequence(count) {
        if (!playerAdapter || !playerAdapter.ready || count <= 0) {
            return;
        }

        switch (count) {
            case 1:
                playerAdapter.togglePlayback()
                break
            case 2:
                playerAdapter.nextTrack()
                break
            default:
                playerAdapter.previousTrack()
                break
        }
    }

    function formatLyricsSource(source) {
        return L10n.providerName(source);
    }

    /* Artwork update handler */
    function updateArtwork() {
        if (playerAdapter.ready) {
            let url = playerAdapter.artworkUrl;
            if (url && url.startsWith("https://") && !plasmoid.configuration.fetchAlbumCoverHttps) {
                url = url.replace("https://", "http://");
            }
            artwork.source = url || artwork.fallbackSource;
        }
    }

    /* Lyrics update handler */
    function updateLyrics() {
        if (playerAdapter && playerAdapter.ready) {
            const requestToken = ++lyricsRequestToken;
            const requestedIdentity = playerAdapter.identity;
            const requestedTrack = playerAdapter.track;
            const requestedArtist = playerAdapter.artist;
            const requestedAlbum = playerAdapter.album;
            const requestedMetadata = playerAdapter.metadata;

            lyricsLoading = true;
            instrumentalHint = isInstrumentalTrack(requestedTrack, requestedArtist, requestedAlbum, requestedMetadata);
            lyricsRenderer.lyricsPayload = null;

            lyricsLrcLib.fetchLyricsPayload(requestedTrack, requestedArtist, requestedAlbum, requestedMetadata)
                .then(payload => {
                if (widget
                    && requestToken === lyricsRequestToken
                    && requestedIdentity === playerAdapter.identity
                    && requestedTrack === playerAdapter.track
                    && requestedArtist === playerAdapter.artist
                    && requestedAlbum === playerAdapter.album) {
                    lyricsLoading = false;
                    lyricsRenderer.lyricsPayload = payload;
                }
            })
                .catch(error => {
                    if (widget && requestToken === lyricsRequestToken) {
                        lyricsLoading = false;
                    }
                    console.warn("Lyrics request failed:", error);
                })
        } else {
            lyricsLoading = false;
            instrumentalHint = false;
            lyricsRenderer.lyricsPayload = null;
        }
    }
}
