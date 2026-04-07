import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.mpris as Mpris
import "Localizer.js" as L10n

KCM.SimpleKCM {
    property bool cfg_showLyricsDefault
    property bool cfg_highlightCurrentLineDefault
    property int cfg_lyricsFontSizeDefault
    property bool cfg_alternativeLineHeightCalculationDefault
    property string cfg_lyricsFontFamilyDefault

    property bool cfg_showAlbumCoverDefault
    property bool cfg_fetchAlbumCoverHttpsDefault
    property int cfg_maxTitleArtistLengthDefault
    property bool cfg_showTitleDefault
    property int cfg_titleFontSizeDefault
    property string cfg_titleFontFamilyDefault
    property bool cfg_showArtistDefault
    property int cfg_artistFontSizeDefault
    property string cfg_artistFontFamilyDefault

    property alias cfg_transparentBackground: transparentBackground.checked

    property alias cfg_showLyrics: showLyrics.checked
    property alias cfg_highlightCurrentLine: highlightCurrentLine.checked
    property alias cfg_lyricsFontSize: lyricsFontSize.value
    property alias cfg_alternativeLineHeightCalculation: alternativeLineHeightCalculation.checked
    property alias cfg_lyricsFontFamily: lyricsFontFamily.currentText
    property alias cfg_enableLrclibProvider: enableLrclibProvider.checked
    property alias cfg_enableMprisMetadataProvider: enableMprisMetadataProvider.checked

    property bool cfg_useCustomLyricsColorDefault
    property alias cfg_useCustomLyricsColor: useCustomLyricsColor.checked
    property string cfg_lyricsTextColor: plasmoid.configuration.lyricsTextColor

    property alias cfg_showAlbumCover: showAlbumCover.checked
    property alias cfg_fetchAlbumCoverHttps: fetchAlbumCoverHttps.checked
    property alias cfg_maxTitleArtistLength: maxTitleArtistLength.value
    property alias cfg_showTitle: showTitle.checked
    property alias cfg_titleFontSize: titleFontSize.value
    property alias cfg_titleFontFamily: titleFontFamily.currentText
    property bool cfg_useCustomTitleColorDefault
    property alias cfg_useCustomTitleColor: useCustomTitleColor.checked
    property string cfg_titleTextColor: plasmoid.configuration.titleTextColor
    property alias cfg_showArtist: showArtist.checked
    property alias cfg_artistFontSize: artistFontSize.value
    property alias cfg_artistFontFamily: artistFontFamily.currentText
    property bool cfg_useCustomArtistColorDefault
    property alias cfg_useCustomArtistColor: useCustomArtistColor.checked
    property string cfg_artistTextColor: plasmoid.configuration.artistTextColor
    property alias cfg_preferredPlayerIdentity: preferredPlayerIdentity.text
    readonly property var detectedPlayers: availablePlayers()

    property var mpris2Model: Mpris.Mpris2Model {
        readonly property int containerRole: Qt.UserRole + 1
    }

    function availablePlayers() {
        let identities = [];

        for (let i = 0; i < mpris2Model.rowCount(); i++) {
            const player = mpris2Model.data(mpris2Model.index(i, 0), mpris2Model.containerRole);
            const identity = player && player.identity ? player.identity.toString().trim() : "";
            if (identity.length > 0 && identities.indexOf(identity) < 0) {
                identities.push(identity);
            }
        }

        return identities.sort();
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: L10n.tr("Appearance", "外观")
            level: 3
            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        CheckBox {
            id: transparentBackground
            text: L10n.tr("Transparent background", "透明背景")
            ToolTip.text: L10n.tr("Use transparent background when plasmoid is on desktop (not in panel)", "当部件放在桌面上而不是面板中时使用透明背景")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }

        // Spacer
        Rectangle {
            Layout.fillWidth: true
            height: 20
            color: "transparent"
        }

        Kirigami.Heading {
            text: L10n.tr("Lyrics", "歌词")
            level: 3
            Layout.alignment: Qt.AlignLeft
        }

        CheckBox {
            id: showLyrics
            text: L10n.tr("Show lyrics", "显示歌词")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            Layout.maximumWidth: 520
            wrapMode: Text.WordWrap
            text: L10n.tr("Synced lyrics are preferred from LRCLIB. If that fails, the plasmoid can fall back to plain lyrics exposed by the active MPRIS player.", "优先使用 LRCLIB 的同步歌词。如果失败，则回退到当前 MPRIS 播放器提供的纯文本歌词。")
            opacity: 0.75
        }

        CheckBox {
            id: highlightCurrentLine
            text: L10n.tr("Highlight current line", "高亮当前行")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showLyrics.checked
        }

        CheckBox {
            id: alternativeLineHeightCalculation
            text: L10n.tr("Use alternative scroll offset calculation (Works better with some fonts)", "使用替代滚动偏移计算方式（某些字体效果更好）")
            ToolTip.text: L10n.tr("Use an alternative method to calculate line height which may work better with some fonts.", "使用另一种行高计算方法，某些字体下效果更好。")
            Layout.alignment: Qt.AlignLeft
            enabled: showLyrics.checked
            Layout.leftMargin: 20
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: 20
            enabled: showLyrics.checked

            Label {
                text: L10n.tr("Lyrics Font:", "歌词字体：")
                Layout.alignment: Qt.AlignLeft
            }

            ComboBox {
                id: lyricsFontFamily
                model: Qt.fontFamilies()
                editable: true
                Layout.alignment: Qt.AlignLeft

                Component.onCompleted: {
                    const index = model.indexOf(plasmoid.configuration.lyricsFontFamily)
                    currentIndex = index >= 0 ? index : 0
                }
            }

            SpinBox {
                id: lyricsFontSize
                from: 8
                to: 72
                stepSize: 1
                Layout.alignment: Qt.AlignLeft
            }
        }

        CheckBox {
            id: enableLrclibProvider
            text: L10n.tr("Enable LRCLIB provider", "启用 LRCLIB 来源")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showLyrics.checked
        }

        CheckBox {
            id: enableMprisMetadataProvider
            text: L10n.tr("Enable MPRIS metadata lyrics fallback", "启用 MPRIS 元数据歌词回退")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showLyrics.checked
        }

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 40
            Layout.maximumWidth: 520
            wrapMode: Text.WordWrap
            text: L10n.tr("Keep both providers enabled for the most robust experience. LRCLIB gives synced lines when available, while MPRIS metadata can still show plain text lyrics.", "建议同时启用两个来源以获得最稳妥的体验。LRCLIB 提供同步歌词，MPRIS 元数据则可在失败时显示纯文本歌词。")
            opacity: 0.7
            visible: showLyrics.checked
        }

        CheckBox {
            id: useCustomLyricsColor
            text: L10n.tr("Use custom lyrics text color", "使用自定义歌词颜色")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showLyrics.checked
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: 40
            enabled: showLyrics.checked && useCustomLyricsColor.checked

            Label {
                text: L10n.tr("Lyrics Color:", "歌词颜色：")
                Layout.alignment: Qt.AlignLeft
            }

            Rectangle {
                width: 40
                height: 24
                radius: 4
                color: cfg_lyricsTextColor
                border.color: Kirigami.Theme.textColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: lyricsColorDialog.open()
                }
            }

            Label {
                text: cfg_lyricsTextColor
                Layout.alignment: Qt.AlignLeft
                opacity: 0.7
            }
        }

        ColorDialog {
            id: lyricsColorDialog
            title: L10n.tr("Choose lyrics text color", "选择歌词颜色")
            selectedColor: cfg_lyricsTextColor
            onAccepted: {
                cfg_lyricsTextColor = selectedColor.toString()
            }
        }

        // Spacer
        Rectangle {
            Layout.fillWidth: true
            height: 20
            color: "transparent"
        }

        Kirigami.Heading {
            text: L10n.tr("Player", "播放器")
            level: 3
            Layout.alignment: Qt.AlignLeft
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: L10n.tr("Preferred player identity:", "首选播放器标识：")
                Layout.alignment: Qt.AlignLeft
            }

            TextField {
                id: preferredPlayerIdentity
                Layout.fillWidth: true
                placeholderText: L10n.tr("Spotify", "Spotify")

                Component.onCompleted: {
                    text = plasmoid.configuration.preferredPlayerIdentity || ""
                }
            }

            Button {
                text: L10n.tr("Clear", "清除")
                enabled: preferredPlayerIdentity.text.length > 0
                onClicked: preferredPlayerIdentity.text = ""
            }
        }

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.maximumWidth: 520
            wrapMode: Text.WordWrap
            text: L10n.tr("Leave this empty to use the first available player. If more than one player is running, pick one of the detected identities below.", "留空时将使用第一个可用播放器。如果同时运行多个播放器，可以从下方检测到的标识中选择。")
            opacity: 0.75
        }

        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: detectedPlayers.length > 0

            Repeater {
                model: detectedPlayers

                Button {
                    required property string modelData
                    text: modelData
                    flat: preferredPlayerIdentity.text !== modelData
                    highlighted: preferredPlayerIdentity.text === modelData
                    onClicked: preferredPlayerIdentity.text = modelData
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            text: L10n.tr("No running MPRIS players detected right now.", "当前未检测到正在运行的 MPRIS 播放器。")
            opacity: 0.65
            visible: detectedPlayers.length === 0
        }

        Kirigami.Heading {
            text: L10n.tr("Track Information", "曲目信息")
            level: 3
            Layout.alignment: Qt.AlignLeft
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        CheckBox {
            id: showAlbumCover
            text: L10n.tr("Show album cover", "显示专辑封面")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            CheckBox {
                id: fetchAlbumCoverHttps
                text: L10n.tr("Fetch album cover over HTTPS (Causes issues)", "通过 HTTPS 获取专辑封面（可能有问题）")
                ToolTip.text: L10n.tr("Use HTTPS to fetch album covers. This could cause issues with the current KDE Plasma version.", "使用 HTTPS 获取专辑封面。当前 KDE Plasma 版本下这可能引发问题。")
                Layout.alignment: Qt.AlignLeft
                enabled: showAlbumCover.checked
                Layout.leftMargin: 20
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: L10n.tr("Max title/artist length:", "标题/艺术家最大长度：")
                Layout.alignment: Qt.AlignLeft
            }

            SpinBox {
                id: maxTitleArtistLength
                from: 10
                to: 200
                stepSize: 1
                Layout.alignment: Qt.AlignLeft
                enabled: showAlbumCover.checked
            }
        }

        CheckBox {
            id: showTitle
            text: L10n.tr("Show title", "显示标题")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            checked: plasmoid.configuration.showTitle
            onCheckedChanged: plasmoid.configuration.showTitle = checked
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.largeSpacing

            Label {
                text: L10n.tr("Title Font:", "标题字体：")
                Layout.alignment: Qt.AlignLeft
            }

            ComboBox {
                id: titleFontFamily
                model: Qt.fontFamilies()
                editable: true
                Layout.alignment: Qt.AlignLeft

                Component.onCompleted: {
                    const index = model.indexOf(plasmoid.configuration.titleFontFamily)
                    currentIndex = index >= 0 ? index : 0
                }
            }

            SpinBox {
                id: titleFontSize
                from: 8
                to: 72
                stepSize: 1
                Layout.alignment: Qt.AlignLeft
            }
        }

        CheckBox {
            id: useCustomTitleColor
            text: L10n.tr("Use custom title text color", "使用自定义标题颜色")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showTitle.checked
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: 40
            enabled: showTitle.checked && useCustomTitleColor.checked

            Label {
                text: L10n.tr("Title Color:", "标题颜色：")
                Layout.alignment: Qt.AlignLeft
            }

            Rectangle {
                width: 40
                height: 24
                radius: 4
                color: cfg_titleTextColor
                border.color: Kirigami.Theme.textColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: titleColorDialog.open()
                }
            }

            Label {
                text: cfg_titleTextColor
                Layout.alignment: Qt.AlignLeft
                opacity: 0.7
            }
        }

        ColorDialog {
            id: titleColorDialog
            title: L10n.tr("Choose title text color", "选择标题颜色")
            selectedColor: cfg_titleTextColor
            onAccepted: {
                cfg_titleTextColor = selectedColor.toString()
            }
        }

        CheckBox {
            id: showArtist
            text: L10n.tr("Show artist", "显示艺术家")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Kirigami.Units.largeSpacing
            checked: plasmoid.configuration.showArtist
            onCheckedChanged: plasmoid.configuration.showArtist = checked
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: Kirigami.Units.largeSpacing

            Label {
                text: L10n.tr("Artist Font:", "艺术家字体：")
                Layout.alignment: Qt.AlignLeft
            }

            ComboBox {
                id: artistFontFamily
                model: Qt.fontFamilies()
                editable: true
                Layout.alignment: Qt.AlignLeft

                Component.onCompleted: {
                    const index = model.indexOf(plasmoid.configuration.artistFontFamily)
                    currentIndex = index >= 0 ? index : 0
                }
            }

            SpinBox {
                id: artistFontSize
                from: 8
                to: 72
                stepSize: 1
                Layout.alignment: Qt.AlignLeft
            }
        }

        CheckBox {
            id: useCustomArtistColor
            text: L10n.tr("Use custom artist text color", "使用自定义艺术家颜色")
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: 20
            enabled: showArtist.checked
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Kirigami.Units.smallSpacing
            Layout.leftMargin: 40
            enabled: showArtist.checked && useCustomArtistColor.checked

            Label {
                text: L10n.tr("Artist Color:", "艺术家颜色：")
                Layout.alignment: Qt.AlignLeft
            }

            Rectangle {
                width: 40
                height: 24
                radius: 4
                color: cfg_artistTextColor
                border.color: Kirigami.Theme.textColor
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: artistColorDialog.open()
                }
            }

            Label {
                text: cfg_artistTextColor
                Layout.alignment: Qt.AlignLeft
                opacity: 0.7
            }
        }

        ColorDialog {
            id: artistColorDialog
            title: L10n.tr("Choose artist text color", "选择艺术家颜色")
            selectedColor: cfg_artistTextColor
            onAccepted: {
                cfg_artistTextColor = selectedColor.toString()
            }
        }
    }
}
