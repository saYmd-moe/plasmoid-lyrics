.pragma library

function isChineseLocale() {
    return Qt.locale().name.toLowerCase().startsWith("zh");
}

function tr(englishText, chineseText) {
    return isChineseLocale() ? chineseText : englishText;
}

function providerName(source) {
    switch (source) {
        case "lrclib":
            return tr("LRCLIB", "LRCLIB");
        case "mpris-metadata":
            return tr("MPRIS metadata", "MPRIS 元数据");
        default:
            return source || tr("unknown", "未知");
    }
}

function lyricsMode(mode) {
    switch (mode) {
        case "synced":
            return tr("synced", "同步");
        case "plain":
            return tr("plain", "纯文本");
        default:
            return mode || tr("unknown", "未知");
    }
}
