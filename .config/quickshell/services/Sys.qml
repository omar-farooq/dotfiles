pragma Singleton

// CPU, memory and disk, read straight from the kernel.
//
// waybar's cpu/memory/disk modules did this internally; here it is explicit,
// which at least makes the sampling interval and the CPU maths visible rather
// than folded into the bar.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property int disk: 0

    // -----------------------------------------------------------------
    // CPU
    //
    // /proc/stat's first line is cumulative jiffies since boot, so a usage
    // percentage needs two samples and the delta between them. Reading it once
    // gives the average since boot, which is a different (and useless) number.
    // -----------------------------------------------------------------

    property var lastCpu: null

    FileView {
        id: statFile

        path: "/proc/stat"
        preload: true
        onLoaded: root.sampleCpu(statFile.text())
    }

    function sampleCpu(text) {
        // "cpu  user nice system idle iowait irq softirq steal ..."
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 4)
            return;

        const total = fields.reduce((a, b) => a + b, 0);
        const idle = fields[3] + (fields[4] || 0);   // idle + iowait

        if (root.lastCpu) {
            const dTotal = total - root.lastCpu.total;
            const dIdle = idle - root.lastCpu.idle;
            if (dTotal > 0)
                root.cpu = Math.round(100 * (dTotal - dIdle) / dTotal);
        }

        root.lastCpu = {
            total: total,
            idle: idle
        };
    }

    // -----------------------------------------------------------------
    // Memory
    //
    // MemAvailable, not MemFree: free memory excludes the page cache, so it
    // reads as ~95% used on any machine that has been up more than an hour.
    // Available is the kernel's own estimate of what a new process could get.
    // -----------------------------------------------------------------

    FileView {
        id: memFile

        path: "/proc/meminfo"
        preload: true
        onLoaded: root.sampleMemory(memFile.text())
    }

    function sampleMemory(text) {
        const read = key => {
            const m = new RegExp(`^${key}:\\s+(\\d+)`, "m").exec(text);
            return m ? Number(m[1]) : 0;
        };

        const total = read("MemTotal");
        const available = read("MemAvailable");
        if (total > 0)
            root.memory = Math.round(100 * (total - available) / total);
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }

    // -----------------------------------------------------------------
    // Disk
    //
    // Not from /proc -- statvfs has no procfs equivalent, so this is the one
    // that has to shell out. Sixty seconds is plenty: the root filesystem does
    // not change occupancy fast enough to care.
    // -----------------------------------------------------------------

    Process {
        id: dfProc

        command: ["df", "--output=pcent", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                const m = /(\d+)%/.exec(text);
                if (m)
                    root.disk = Number(m[1]);
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!dfProc.running)
            dfProc.running = true
    }
}
