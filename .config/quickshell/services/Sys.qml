pragma Singleton

// CPU, memory and disk, read straight from the kernel.
//
// waybar's cpu/memory/disk modules did this internally; here it is explicit,
// which at least makes the sampling interval and the CPU maths visible rather
// than folded into the bar.
//
// Everything here is kept as history as well as a current value. A percentage
// on its own answers "how busy now" and nothing else -- 40% climbing and 40%
// falling look identical on a bar, and the direction is the half that tells you
// whether to go looking. The samples are cheap; keeping the last forty of each
// costs nothing and is what the sparklines draw.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property int disk: 0

    // -----------------------------------------------------------------
    // History
    //
    // Forty samples. At the three-second CPU interval that is two minutes of
    // past, which is about as far back as a glance at a bar is worth. Disk is
    // sampled once a minute, so its run covers a much longer stretch of a much
    // flatter curve -- which is honest, disks do not spike.
    // -----------------------------------------------------------------

    readonly property int historyLength: 40

    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []

    // Arrays are replaced rather than pushed into: QML notices the assignment,
    // not the mutation, so an in-place push updates the value and redraws
    // nothing.
    function record(history, value) {
        const out = history.concat(value);
        return out.length > root.historyLength ? out.slice(-root.historyLength) : out;
    }

    // -----------------------------------------------------------------
    // CPU
    //
    // /proc/stat's first line is cumulative jiffies since boot, so a usage
    // percentage needs two samples and the delta between them. Reading it once
    // gives the average since boot, which is a different (and useless) number.
    //
    // The `cpuN` lines under it carry the same counters per core and get the
    // same treatment in the same pass -- same file, same arithmetic, so a
    // separate reader for them would only be a second chance to disagree.
    // -----------------------------------------------------------------

    // Per core, in the kernel's order. Twenty entries on this machine, but
    // nothing should assume a count -- read it from the array.
    property var cores: []

    property var lastCpu: null    // { total, idle } for the aggregate line
    property var lastCores: []    // the same, one per core

    FileView {
        id: statFile

        path: "/proc/stat"
        preload: true
        onLoaded: root.sampleCpu(statFile.text())
    }

    function sampleCpu(text) {
        const cores = [];
        const coreSamples = [];

        for (const line of text.split("\n")) {
            // The cpu lines are the first thing in the file and contiguous, so
            // the first line that is not one of them ends the interesting part.
            if (!line.startsWith("cpu"))
                break;

            // "cpu  user nice system idle iowait irq softirq steal ..."
            const parts = line.trim().split(/\s+/);
            const fields = parts.slice(1).map(Number);
            if (fields.length < 4)
                continue;

            const total = fields.reduce((a, b) => a + b, 0);
            const idle = fields[3] + (fields[4] || 0);   // idle + iowait

            if (parts[0] === "cpu") {
                const percent = root.busy(root.lastCpu, total, idle);
                if (percent !== null) {
                    root.cpu = percent;
                    root.cpuHistory = root.record(root.cpuHistory, percent);
                }

                root.lastCpu = {
                    total: total,
                    idle: idle
                };
            } else {
                const percent = root.busy(root.lastCores[coreSamples.length], total, idle);

                // Zero on the very first read, where there is no previous
                // sample to subtract. One frame of empty bars beats a hole in
                // the grid while the second sample is three seconds away.
                cores.push(percent === null ? 0 : percent);
                coreSamples.push({
                    total: total,
                    idle: idle
                });
            }
        }

        root.cores = cores;
        root.lastCores = coreSamples;
    }

    // Percentage busy between a previous cumulative sample and this one, or
    // null when there is nothing to compare against yet.
    function busy(last, total, idle) {
        if (!last)
            return null;

        const dTotal = total - last.total;
        if (dTotal <= 0)
            return null;

        return Math.round(100 * (dTotal - (idle - last.idle)) / dTotal);
    }

    // -----------------------------------------------------------------
    // Memory
    //
    // MemAvailable, not MemFree: free memory excludes the page cache, so it
    // reads as ~95% used on any machine that has been up more than an hour.
    // Available is the kernel's own estimate of what a new process could get.
    // -----------------------------------------------------------------

    // Bytes, and `real` rather than `int` deliberately: 32GB of RAM overflows a
    // signed 32-bit int, and the disk figures below are larger still.
    property real memoryUsed: 0
    property real memoryTotal: 0

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

        // meminfo is in kB.
        const total = read("MemTotal") * 1024;
        const available = read("MemAvailable") * 1024;
        if (total <= 0)
            return;

        root.memoryTotal = total;
        root.memoryUsed = total - available;
        root.memory = Math.round(100 * root.memoryUsed / total);
        root.memoryHistory = root.record(root.memoryHistory, root.memory);
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

    property real diskUsed: 0
    property real diskTotal: 0

    Process {
        id: dfProc

        // -B1 for bytes rather than -h: the panel wants to do its own rounding,
        // and df's "161G" would have to be parsed back into a number to draw a
        // bar with anyway.
        command: ["df", "-B1", "--output=pcent,used,size", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                // A header line, then " 67% 172704428032 275082035200".
                const m = /(\d+)%\s+(\d+)\s+(\d+)/.exec(text);
                if (!m)
                    return;

                root.disk = Number(m[1]);
                root.diskUsed = Number(m[2]);
                root.diskTotal = Number(m[3]);
                root.diskHistory = root.record(root.diskHistory, root.disk);
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
