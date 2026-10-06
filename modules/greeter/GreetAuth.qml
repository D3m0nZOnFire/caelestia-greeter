pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Services.Pam
import qs.modules.lock

// Drop-in replacement for modules/lock/Pam.qml, so the lock screen's center widgets
// (PasswordInput, InputField, StateMessage) work unchanged.
// Uses greetd when GREETD_SOCK is set; otherwise falls back to a plain PAM check
// against the current user so the greeter can be previewed inside a normal session.
Scope {
    id: root

    required property string user
    required property list<string> sessionCommand

    readonly property bool testMode: !Greetd.available

    readonly property QtObject passwd: QtObject {
        property bool active
        property string message
        function start(): void {
            root.start();
        }
    }
    // Fingerprint/howdy are not supported in the greeter; stubs keep the shared UI happy
    readonly property QtObject fprint: QtObject {
        property bool available
        property bool active
        property bool canAttempt
        property int state
        property int tries
        property string message
    }
    readonly property QtObject howdy: QtObject {
        property bool available
        property bool active
        property bool canAttempt
        property int state
        property int tries
        property string message
    }

    property string lockMessage
    property int state
    property string buffer
    property bool succeeded

    signal flashMsg
    signal success

    function handleKey(event: KeyEvent): void {
        if (passwd.active || succeeded)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                buffer = "";
            else
                buffer = buffer.slice(0, -1);
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text;
        }
    }

    function start(): void {
        if (passwd.active || succeeded)
            return;

        passwd.active = true;
        passwd.message = "";
        if (testMode)
            testPam.start();
        else
            Greetd.createSession(user);
    }

    function fail(res: int, message: string): void {
        passwd.active = false;
        passwd.message = message;
        buffer = "";
        state = res;
        flashMsg();
        stateReset.restart();
    }

    // Called by the surface once the exit animation is done
    function launch(): void {
        if (testMode) {
            console.info(`[greeter] test mode: would launch ${JSON.stringify(sessionCommand)} as ${user}`);
            Qt.quit();
        } else {
            Greetd.launch(sessionCommand);
        }
    }

    Connections {
        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired) {
                Greetd.respond(root.buffer);
                root.buffer = "";
            } else if (error) {
                root.passwd.message = message;
            }
        }

        function onAuthFailure(message: string): void {
            root.fail(Pam.Failed, message);
        }

        function onError(error: string): void {
            console.warn(`[greeter] greetd error: ${error}`);
            Greetd.cancelSession();
            root.fail(Pam.Error, error);
        }

        function onReadyToLaunch(): void {
            root.succeeded = true;
            root.passwd.active = false;
            root.success();
        }

        target: root.testMode ? null : Greetd
    }

    PamContext {
        id: testPam

        config: "passwd"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                root.succeeded = true;
                root.passwd.active = false;
                root.success();
            } else {
                root.fail(res === PamResult.MaxTries ? Pam.MaxTries : res === PamResult.Error ? Pam.Error : Pam.Failed, "");
            }
        }
    }

    Timer {
        id: stateReset

        interval: 4000
        onTriggered: {
            if (root.state !== Pam.MaxTries)
                root.state = Pam.None;
        }
    }
}
