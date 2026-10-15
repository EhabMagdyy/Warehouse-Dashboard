pragma Singleton
import QtQuick

QtObject {
    // --- palette (dark military) ---
    readonly property color background:     "#0B1120"
    readonly property color surface:        "#111827"
    readonly property color surfaceAlt:     "#1A2235"
    readonly property color primary:        "#C9A84C"        // gold
    readonly property color primaryDark:    "#A0832E"
    readonly property color accent:         "#2563EB"        // electric blue
    readonly property color accentSoft:     "#1E3A6E"
    readonly property color textPrimary:    "#F0F4FF"
    readonly property color textSecondary:  '#c1c9dc'
    readonly property color textFaint:      '#9ca5ba'
    readonly property color danger:         "#EF4444"
    readonly property color dangerSoft:     "#3B1111"
    readonly property color success:        "#22C55E"
    readonly property color successSoft:    "#0F2B1A"
    readonly property color warning:        "#F59E0B"

    // --- glass ---
    readonly property color glassFill:         "#1A2235"
    readonly property real  glassFillOpacity:  0.85
    readonly property color glassBorder:       "#C9A84C"
    readonly property real  glassBorderOpacity:0.18

    // --- responsive scale ---
    property real scaleFactor: Math.max(0.75, Math.min(Screen.width / 1600, 1.6))
    function dp(v) { return Math.round(v * scaleFactor) }

    // --- radii ---
    readonly property int radiusSmall:  dp(8)
    readonly property int radiusMedium: dp(14)
    readonly property int radiusLarge:  dp(20)
    readonly property int radiusRound:  dp(999)

    // --- typography ---
    readonly property int fontSizeTitle:  dp(26)
    readonly property int fontSizeHeader: dp(20)
    readonly property int fontSizeBody:   dp(16)
    readonly property int fontSizeSmall:  dp(15)
    readonly property string fontFamily:  "Inter, Roboto, sans-serif"

    // --- spacing ---
    readonly property int spacingXS:     dp(6)
    readonly property int spacingSmall:  dp(10)
    readonly property int spacingMedium: dp(18)
    readonly property int spacingLarge:  dp(28)
    readonly property int pageMargin:    dp(28)
}
