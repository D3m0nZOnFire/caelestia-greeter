//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import "modules/greeter"
import QtQuick
import Quickshell

// Caelestia-styled greetd greeter.
// Env:
//   CAELESTIA_GREETER_USER     user to log in (default: ivo)
//   CAELESTIA_GREETER_MONITOR  monitor that shows the login box (default: first screen)
//   CAELESTIA_GREETER_SESSION  session command, space separated (default: start-hyprland)
ShellRoot {
    id: root

    // Falls back to the first screen if the configured monitor isn't connected
    readonly property string wanted: Quickshell.env("CAELESTIA_GREETER_MONITOR") ?? ""
    readonly property string monitor: Quickshell.screens.some(s => s.name === wanted) ? wanted : ""

    settings.watchFiles: false

    GreetAuth {
        id: auth

        user: Quickshell.env("CAELESTIA_GREETER_USER") || "ivo"
        sessionCommand: (Quickshell.env("CAELESTIA_GREETER_SESSION") || "start-hyprland").split(" ")
    }

    Variants {
        model: Quickshell.screens

        GreeterSurface {
            required property ShellScreen modelData

            screen: modelData
            pam: auth
            primary: root.monitor ? modelData.name === root.monitor : modelData === Quickshell.screens[0]
        }
    }
}
