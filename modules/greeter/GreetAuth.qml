pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Services.Pam
import qs.modules.lock

// Drop-in replacement for modules/lock/Pam.qml, so the lock screen's center widgets
// (PasswordInput, InputField, StateMessage) work unchanged.
// Uses greetd when GREETD_SOCK is set; otherwise falls back to a plain PAM check
// against the current user so the greeter can be previewed inside a normal session.
Scope {
    id: root

    required property list<string> sessionCommand
    // Preselected when no previous login is remembered
    property string defaultUser

    readonly property bool testMode: !Greetd.available

    // Login-capable accounts from /etc/passwd: [{ name, fullName }]
    property var users: []
    property int userIndex: 0
    readonly property var currentUser: users[userIndex] ?? null
    readonly property string user: currentUser?.name ?? ""
    property string lastUser

    function selectUser(offset: int): void {
        if (users.length < 2 || passwd.active || succeeded)
            return;
        userIndex = (userIndex + offset + users.length) % users.length;
        buffer = "";
        passwd.message = "";
        state = Pam.None;
    }

    function pickInitialUser(): void {
        for (const name of [lastUser, defaultUser]) {
            const i = users.findIndex(u => u.name === name);
            if (i >= 0) {
                userIndex = i;
                return;
            }
        }
        userIndex = 0;
    }

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

        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            selectUser(event.key === Qt.Key_Left ? -1 : 1);
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
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
        if (passwd.active || succeeded || !user)
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
        lastUserFile.setText(user);
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

    FileView {
        // CAELESTIA_GREETER_PASSWD is only for previewing with fake accounts
        path: Quickshell.env("CAELESTIA_GREETER_PASSWD") || "/etc/passwd"
        blockLoading: true
        onLoaded: {
            const nologin = /(nologin|false)$/;
            root.users = text().split("\n").map(l => l.split(":")).filter(f => {
                const uid = parseInt(f[2]);
                return f.length >= 7 && uid >= 1000 && uid < 60000 && !nologin.test(f[6]);
            }).map(f => ({
                        name: f[0],
                        fullName: f[4].split(",")[0] || f[0]
                    }));
            root.pickInitialUser();
        }
    }

    // Remembers who logged in last; lives in the greeter's writable cache dir
    FileView {
        id: lastUserFile

        path: `${Quickshell.env("XDG_CACHE_HOME") || "/var/cache/caelestia-greeter"}/last-user`
        blockLoading: true
        blockWrites: true
        printErrors: false
        onLoaded: {
            root.lastUser = text().trim();
            root.pickInitialUser();
        }
    }

    PamContext {
        id: testPam

        user: root.user
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
