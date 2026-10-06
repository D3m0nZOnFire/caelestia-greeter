pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services

// Avatar + name of the selected user, with arrows to switch when there are several.
// Based on modules/lock/center/ProfilePic.qml.
ColumnLayout {
    id: root

    required property int centerWidth
    required property real centerScale
    required property GreetAuth auth

    readonly property bool multiple: auth.users.length > 1
    readonly property string name: auth.currentUser?.name ?? ""
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    spacing: Tokens.spacing.large * centerScale

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        IconButton {
            type: IconButton.Text
            icon: "chevron_left"
            visible: root.multiple
            onClicked: root.auth.selectUser(-1)
        }

        Item {
            id: avatar

            implicitWidth: Math.round(root.centerWidth * (root.multiple ? 0.55 : 0.7))
            implicitHeight: {
                shape.height; // Force update when shape height changes
                return shape.pathBounds().height;
            }

            MaterialShape {
                id: shape

                anchors.centerIn: parent
                implicitSize: avatar.implicitWidth

                shape: MaterialShape.ClamShell
                color: Qt.alpha(root.bgColour, 1)
                opacity: root.bgColour.a
                layer.enabled: true
            }

            MaterialIcon {
                anchors.centerIn: parent

                text: "person"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(avatar.implicitWidth / 3).build()
                visible: accountIcon.status !== Image.Ready && face.status !== Image.Ready
            }

            // ~/.face of the user whose theme is synced (see sync.sh)
            CachingImage {
                id: face

                anchors.fill: shape
                path: faceProbe.exists ? faceProbe.path : ""
                visible: accountIcon.status !== Image.Ready

                layer.enabled: true
                layer.effect: Mask {
                    maskSource: shape
                }
            }

            // Standard per-user avatar, readable by the greeter
            CachingImage {
                id: accountIcon

                anchors.fill: shape
                path: iconProbe.exists ? iconProbe.path : ""

                layer.enabled: true
                layer.effect: Mask {
                    maskSource: shape
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.multiple
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.auth.selectUser(1)
            }
        }

        IconButton {
            type: IconButton.Text
            icon: "chevron_right"
            visible: root.multiple
            onClicked: root.auth.selectUser(1)
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        animate: true
        text: root.auth.currentUser?.fullName ?? ""
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.large.scale(root.centerScale).weight(Font.Medium).build()
    }

    // Probe avatar files first so missing ones don't spam the log
    FileProbe {
        id: iconProbe

        path: root.name ? `/var/lib/AccountsService/icons/${root.name}` : ""
    }

    FileProbe {
        id: faceProbe

        path: root.name && root.name === syncOwner.text().trim() ? `${Quickshell.env("HOME")}/.face` : ""
    }

    component FileProbe: FileView {
        property bool exists

        printErrors: false
        onPathChanged: exists = false
        onLoaded: exists = true
        onLoadFailed: exists = false
    }

    FileView {
        id: syncOwner

        path: `${Quickshell.env("HOME")}/user`
        blockLoading: true
        printErrors: false
    }
}
