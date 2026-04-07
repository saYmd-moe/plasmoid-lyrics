import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: widget

    Plasmoid.status: PlasmaCore.Types.HiddenStatus
    Plasmoid.backgroundHints: plasmoid.configuration.transparentBackground
        ? PlasmaCore.Types.NoBackground
        : PlasmaCore.Types.DefaultBackground

    Layout.preferredWidth: row.implicitWidth
    Layout.preferredHeight: row.implicitHeight

    readonly property int volumeStep: 2
    property int lyricsRequestToken: 0


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
            Plasmoid.status = playerAdapter.ready ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
            if (!playerAdapter.ready) {
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

    /* Mouse click handling */
    MouseArea {
        z: 100
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: playerAdapter && playerAdapter.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        onClicked: (mouse) => {
            switch (mouse.button) {
                case Qt.MiddleButton:
                    playerAdapter.togglePlayback()
                    break
                case Qt.LeftButton:
                    if (playerAdapter.canRaise) {
                        playerAdapter.raise()
                    }
                    break
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
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
            visible: plasmoid.configuration.showLyrics && playerAdapter && playerAdapter.ready && hasLyrics
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
                    text: playerAdapter && playerAdapter.ready ? truncateText(playerAdapter.track, plasmoid.configuration.maxTitleArtistLength) : "Lyrics"

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
                    text: playerAdapter && playerAdapter.ready ? truncateText(playerAdapter.artist, plasmoid.configuration.maxTitleArtistLength) : "No song playing"

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

            lyricsRenderer.lyricsPayload = null;

            lyricsLrcLib.fetchLyricsPayload(requestedTrack, requestedArtist, requestedAlbum, playerAdapter.metadata)
                .then(payload => {
                if (widget
                    && requestToken === lyricsRequestToken
                    && requestedIdentity === playerAdapter.identity
                    && requestedTrack === playerAdapter.track
                    && requestedArtist === playerAdapter.artist
                    && requestedAlbum === playerAdapter.album) {
                    lyricsRenderer.lyricsPayload = payload;
                }
            })
        } else {
            lyricsRenderer.lyricsPayload = null;
        }
    }
}
