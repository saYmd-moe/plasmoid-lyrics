import QtQuick 2.15
import QtQml.Models 2.3
import org.kde.plasma.private.mpris as Mpris

QtObject {

    property var mpris2Model: Mpris.Mpris2Model
    {
        readonly property int containerRole: Qt.UserRole + 1

        function hasPlayer(rowIndex) {
            const player = this.data(this.index(rowIndex, 0), containerRole)
            return !!player;
        }

        onRowsInserted: (_, rowIndex) => {
            if (this.currentIndex < 0 && hasPlayer(rowIndex)) {
                this.currentIndex = rowIndex;
            }
        }

        Component.onCompleted: {
            for (let i = 0; i < this.rowCount(); i++) {
                if (hasPlayer(i)) {
                    this.currentIndex = i;
                    break;
                }
            }
        }
    }

    readonly property var player: {
        return mpris2Model.currentPlayer
    }

    readonly property bool ready: {
        return !!player
    }

    readonly property string track: ready ? player.track : null
    readonly property string artist: ready ? player.artist : null
    readonly property string album: ready ? player.album : null

    readonly property double position: ready ? player.position : 0
    readonly property double length: ready ? player.length : 0

    readonly property bool playing: ready ? player.playbackStatus === Mpris.PlaybackStatus.Playing : false

    readonly property string artworkUrl: ready ? player.artUrl : null

    readonly property bool canRaise: ready ? player.canRaise : false

    property var timeLastPositionChanged: new Date().getTime()

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

    function changeVolume(delta, showOSD) {
        if (ready) {
            player.changeVolume(delta, showOSD);
        }
    }

}
