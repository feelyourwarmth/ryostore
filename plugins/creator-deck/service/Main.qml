pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Creator Deck service: persistent, non-visual state. Polls `ryoku-creator-deck
// status` for the aspect target, disk headroom, mic state, and recent
// recordings, and fires the action verbs the content taps. Lives as long as the
// plugin is enabled; the content reads it through pluginApi.mainInstance.
Item {
    id: root

    property var pluginApi
    readonly property string bin: (pluginApi && pluginApi.pluginDir ? pluginApi.pluginDir : "") + "/bin/ryoku-creator-deck"

    property string aspect: "9:16"
    property string project: ""
    property string disk: ""
    property bool micMuted: false
    property var recent: []

    function refresh() {
        if (root.bin.length > 1)
            statusProc.running = true;
    }

    function run(args) {
        if (root.bin.length <= 1)
            return;
        Quickshell.execDetached(["bash", root.bin].concat(args));
        refreshTimer.restart();
    }

    // let an action land, then re-read state.
    Timer {
        id: refreshTimer
        interval: 900
        onTriggered: root.refresh()
    }

    Process {
        id: statusProc
        command: ["bash", root.bin, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var o = JSON.parse(this.text || "{}");
                    root.aspect = o.aspect || "9:16";
                    root.project = o.project || "";
                    root.disk = o.disk || "";
                    root.micMuted = o.micMuted === true;
                    root.recent = o.recent || [];
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: root.refresh()
}
