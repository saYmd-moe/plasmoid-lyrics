import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import "Localizer.js" as L10n

Text {
    id: textElement
    Layout.fillWidth: true
    Layout.preferredHeight: parent.height
    Layout.rightMargin: 15
    Layout.leftMargin: 15
    wrapMode: Text.NoWrap
    horizontalAlignment: (centeredLyrics || showStatusState) ? Text.AlignHCenter : Text.AlignRight
    Layout.alignment: (centeredLyrics || showStatusState) ? Qt.AlignHCenter | Qt.AlignVCenter : Qt.AlignLeft
    textFormat: Text.RichText

    text: L10n.tr("Lyrics", "歌词")
    color: plasmoid.configuration.useCustomLyricsColor ? plasmoid.configuration.lyricsTextColor : Kirigami.Theme.textColor
    font.pixelSize: plasmoid.configuration.lyricsFontSize
    font.family: plasmoid.configuration.lyricsFontFamily
    lineHeightMode: Text.FixedHeight
    lineHeight: font.pixelSize + font.pixelSize * 0.2

    property var lyricsPayload: null
    property var playerAdapter: null
    property bool loading: false
    property var transitionDuration: 1000
    property var lineCount: 0
    property var renderedLineIndex: -1
    property var renderedHighlighted: false
    property bool centeredLyrics: false
    readonly property bool hasLyrics: currentLyrics.length > 0
    readonly property bool showStatusState: loading || !hasLyrics
    readonly property var currentLyrics: lyricsPayload && lyricsPayload.lines ? lyricsPayload.lines : []
    readonly property string lyricsMode: lyricsPayload && lyricsPayload.mode ? lyricsPayload.mode : "synced"

    function darkenColor(hexColor, factor) {
        // factor 0.0 = black, 1.0 = original color
        let hex = hexColor.replace("#", "");
        if (hex.length === 3) {
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
        }
        let r = Math.round(parseInt(hex.substring(0, 2), 16) * factor);
        let g = Math.round(parseInt(hex.substring(2, 4), 16) * factor);
        let b = Math.round(parseInt(hex.substring(4, 6), 16) * factor);
        r = Math.min(255, Math.max(0, r));
        g = Math.min(255, Math.max(0, g));
        b = Math.min(255, Math.max(0, b));
        return "#" + r.toString(16).padStart(2, "0") + g.toString(16).padStart(2, "0") + b.toString(16).padStart(2, "0");
    }

    Connections {
        target: plasmoid.configuration
        function onUseCustomLyricsColorChanged() { updateText() }
        function onLyricsTextColorChanged() { updateText() }
        function onHighlightCurrentLineChanged() { updateText() }
    }

    onLoadingChanged: {
        updateText()
        updateTargetPosition(false)
    }

    onLyricsPayloadChanged: {
        if (!plasmoid.configuration.highlightCurrentLine) {
            updateText();
        }
        updateTargetPosition(false)
    }

    Timer {
        interval: 250
        running: playerAdapter && playerAdapter.ready && playerAdapter.playing && lyricsMode === "synced" && hasLyrics
        repeat: true
        onTriggered: {
            updateTargetPosition()
        }
    }

    NumberAnimation on y {
        id: animation
        duration: transitionDuration
        easing.type: Easing.InOutQuad
    }

    function updateText() {
        let builder = "";
        let lines = 0;
        let currentLineIndex = getCurrentLineIndex();
        let highlight = plasmoid.configuration.highlightCurrentLine;
        let useCustomColor = plasmoid.configuration.useCustomLyricsColor;
        let canHighlight = highlight && lyricsMode === "synced";
        let unhighlightedColor = useCustomColor
            ? darkenColor(plasmoid.configuration.lyricsTextColor, 0.45)
            : "gray";

        if (showStatusState) {
            builder = loading
                ? `<span style="color:${unhighlightedColor}">${L10n.tr("Looking up lyrics...", "正在查找歌词...")}</span>`
                : `<span style="color:${unhighlightedColor}">${L10n.tr("No lyrics available", "没有可用歌词")}</span>`;
            lines = 1;
            renderedLineIndex = -1;
            renderedHighlighted = false;
        } else if (lyricsMode === "plain") {
            const sourceName = formatSourceName(lyricsPayload ? lyricsPayload.source : "");
            if (sourceName) {
                builder += `<span style="color:${unhighlightedColor}">${sourceName}</span><br/>`;
                lines++;
            }

            currentLyrics.forEach((line, i) => {
                builder += line.text;
                if (i < currentLyrics.length - 1) {
                    builder += "<br/>";
                }
                lines++;
            });
            renderedLineIndex = -1;
            renderedHighlighted = false;
        } else if (hasLyrics) {
            currentLyrics.forEach((line, i) => {
                if (i === currentLineIndex || !canHighlight) {
                    builder += line.text;
                } else {
                    builder += `<span style="color:${unhighlightedColor}">${line.text}</span>`;
                }

                if (i < currentLyrics.length - 1) {
                    builder += "<br/>";
                }
                lines++;
            });
        }

        lineCount = lines;
        textElement.text = builder;
        if (!showStatusState && lyricsMode === "synced") {
            renderedLineIndex = currentLineIndex;
            renderedHighlighted = canHighlight;
        }
    }

    function updateTargetPosition(animated = true) {
        let currentY = y;

        if (canUpdateText()) {
            updateText();
        }

        if (textElement.parent !== null && lineCount > 0) {
            if (animated) {
                animation.from = currentY;
                animation.to = calculateTargetY();
                animation.start()
            } else {
                animation.stop()
                y = calculateTargetY()
            }
        } else {
            y = textElement.parent.height / 2 - textElement.lineHeight / 2;
        }
    }

    function canUpdateText() {
        let highlight = plasmoid.configuration.highlightCurrentLine;
        if (showStatusState || lyricsMode !== "synced") {
            return renderedHighlighted !== false;
        }
        if (renderedHighlighted !== highlight) {
            return true;
        }

        let currentLineIndex = getCurrentLineIndex();
        if (renderedLineIndex === currentLineIndex) {
            return false;
        }

        return highlight;
    }

    function getCurrentLineIndex(offset = 0) {
        if (showStatusState || lyricsMode !== "synced" || !hasLyrics || !playerAdapter) {
            return -1;
        }

        let position = playerAdapter.getDaemonPosition() / 1_000_000 + offset;
        let target = -1;
        for (let i = 0; i < currentLyrics.length; i++) {
            if (currentLyrics[i].time <= position) {
                target = i;
            } else {
                break;
            }
        }
        return target;
    }

    function calculateTargetY() {
        if (showStatusState || lyricsMode !== "synced") {
            return textElement.parent.height / 2 - textElement.lineHeight / 2;
        }

        let currentLineIndex = getCurrentLineIndex(transitionDuration / 1000 / 2);
        if (!(currentLineIndex >= 0 && lineCount > 0)) {
            return textElement.parent.height / 2 - textElement.lineHeight / 2;
        }

        // Fix for - Lyrics scroll too fast #2
        if (plasmoid.configuration.alternativeLineHeightCalculation) {
            let offsetY = 0;
            let lineHeight = (textElement.contentHeight - 3) / textElement.lineCount;
            if (hasLyrics && currentLineIndex >= 0) {
                offsetY = lineHeight * (currentLineIndex + 1);
            }
            return textElement.parent.height / 2 - offsetY + lineHeight / 2 - 3;
        }

        let lineHeight = textElement.lineHeight;
        let visibleLines = Math.floor(textElement.height / lineHeight);
        let targetLineInView = Math.floor(visibleLines / 2);

        let targetLineIndex = currentLineIndex - targetLineInView;
        return -targetLineIndex * lineHeight;
    }

    function formatSourceName(source) {
        return L10n.providerName(source);
    }

}
