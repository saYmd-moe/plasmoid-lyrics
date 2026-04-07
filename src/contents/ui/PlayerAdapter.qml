import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.plasmoid

QtObject {

    property string preferredPlayerIdentity: plasmoid.configuration.preferredPlayerIdentity || ""
    property var mpris2Model: Mpris.Mpris2Model
    {
        readonly property int containerRole: Qt.UserRole + 1

        function hasPlayer(rowIndex) {
            const player = this.data(this.index(rowIndex, 0), containerRole)
            return !!player
        }

        onRowsInserted: selectPlayer()
        onRowsRemoved: selectPlayer()
        onModelReset: selectPlayer()
        Component.onCompleted: selectPlayer()
    }

    readonly property var player: {
        return mpris2Model.currentPlayer
    }

    readonly property bool ready: {
        return !!player
    }

    readonly property string identity: ready ? (player.identity || "") : ""
    readonly property var metadata: ready ? playerMetadata(player) : ({})

    readonly property string track: ready ? player.track : null
    readonly property string artist: ready ? player.artist : null
    readonly property string album: ready ? player.album : null

    readonly property double position: ready ? player.position : 0
    readonly property double length: ready ? player.length : 0

    readonly property bool playing: ready ? player.playbackStatus === Mpris.PlaybackStatus.Playing : false

    readonly property string artworkUrl: ready ? player.artUrl : null

    readonly property bool canRaise: ready ? player.canRaise : false
    readonly property bool canGoNext: ready ? player.canGoNext : false
    readonly property bool canGoPrevious: ready ? player.canGoPrevious : false

    property var timeLastPositionChanged: new Date().getTime()

    function normalizeIdentity(value) {
        return (value || "").trim().toLowerCase()
    }

    function playerAt(rowIndex) {
        return mpris2Model.data(mpris2Model.index(rowIndex, 0), mpris2Model.containerRole)
    }

    function playerMetadata(playerObject) {
        if (!playerObject) {
            return {}
        }

        if (playerObject.metadata !== undefined && playerObject.metadata !== null) {
            return playerObject.metadata
        }

        if (playerObject.metaData !== undefined && playerObject.metaData !== null) {
            return playerObject.metaData
        }

        return {}
    }

    function selectPlayer() {
        let preferredIdentity = normalizeIdentity(preferredPlayerIdentity)
        let fallbackIndex = -1
        let preferredIndex = -1

        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const candidate = playerAt(i)
            if (!candidate) {
                continue
            }

            if (fallbackIndex < 0) {
                fallbackIndex = i
            }

            if (preferredIdentity && normalizeIdentity(candidate.identity) === preferredIdentity) {
                preferredIndex = i
                break
            }
        }

        if (preferredIndex >= 0 && mpris2Model.currentIndex !== preferredIndex) {
            mpris2Model.currentIndex = preferredIndex
            return
        }

        if (mpris2Model.currentIndex >= 0 && playerAt(mpris2Model.currentIndex)) {
            return
        }

        if (fallbackIndex >= 0 && mpris2Model.currentIndex !== fallbackIndex) {
            mpris2Model.currentIndex = fallbackIndex
        }
    }

    function getDaemonPosition() {
        let timePassed = new Date().getTime() - timeLastPositionChanged
        return position + (playing ? (timePassed * 1_000) : 0)
    }

    onPositionChanged: {
        timeLastPositionChanged = new Date().getTime()
    }

    onTrackChanged: {
        timeLastPositionChanged = new Date().getTime()
    }

    onPlayingChanged: {
        timeLastPositionChanged = new Date().getTime()
    }

    onPreferredPlayerIdentityChanged: selectPlayer()

    function raise() {
        if (ready) {
            player.Raise()
        }
    }

    function togglePlayback() {
        if (ready) {
            player.PlayPause()
        }
    }

    function nextTrack() {
        if (ready && canGoNext) {
            player.Next()
        }
    }

    function previousTrack() {
        if (ready && canGoPrevious) {
            player.Previous()
        }
    }

    function changeVolume(delta, showOSD) {
        if (ready) {
            player.changeVolume(delta, showOSD);
        }
    }

}
