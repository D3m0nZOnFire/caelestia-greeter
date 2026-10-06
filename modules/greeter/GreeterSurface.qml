pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.modules.lock

// Adapted from modules/lock/LockSurface.qml: a layer-shell window instead of a
// session lock surface, with only the center column (clock, avatar, password).
PanelWindow {
    id: root

    required property GreetAuth pam
    required property bool primary

    readonly property alias unlocking: exitAnim.running

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    WlrLayershell.namespace: "caelestia-greeter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "black"

    Connections {
        function onSuccess(): void {
            exitAnim.start();
        }

        target: root.pam
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.size
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.radius
            }
            Anim {
                target: content
                property: "scale"
                to: 0
            }
            Anim {
                target: content
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                type: Anim.StandardLarge
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    type: Anim.Standard
                    target: lockContent
                    property: "opacity"
                    to: 0
                }
            }
        }
        ScriptAction {
            script: if (root.primary)
                root.pam.launch()
        }
    }

    ParallelAnimation {
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockContent
                    property: "scale"
                    to: 1
                    type: Anim.FastSpatial
                }
                Anim {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    duration: Tokens.anim.durations.expressiveFastSpatial
                    easing: Tokens.anim.standardAccel
                }
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: lockIcon
                    property: "opacity"
                    to: 0
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: content
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: content
                    property: "scale"
                    to: 1
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: lockContent.Tokens.rounding.extraLarge * 1.5
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: lockContent.fullWidth
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: lockContent.fullHeight
                }
            }
        }
    }

    Item {
        id: background

        anchors.fill: parent
        opacity: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        CachingImage {
            anchors.fill: parent
            path: Wallpapers.current
        }
    }

    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Tokens.padding.large * 4
        readonly property int radius: size / 4 * Tokens.rounding.scale
        readonly property real fullHeight: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult
        readonly property real fullWidth: Math.max(center.implicitWidth, center.centerWidth) + Tokens.padding.extraLargeIncreased * 3

        anchors.centerIn: parent
        implicitWidth: size
        implicitHeight: size

        visible: root.primary
        rotation: 180
        scale: 0

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: parent.radius
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
            }
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(4).weight(Font.Bold).build()
            rotation: 180
        }

        RowLayout {
            id: content

            anchors.centerIn: parent
            width: lockContent.fullWidth - Tokens.padding.extraLargeIncreased
            height: lockContent.fullHeight - Tokens.padding.extraLargeIncreased

            opacity: 0
            scale: 0

            Center {
                id: center

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.max(implicitWidth, centerWidth)
                lock: root
            }
        }
    }
}
