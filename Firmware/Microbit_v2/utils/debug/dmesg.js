#!/usr/bin/env node
"use strict";

let fs = require("fs")
let child_process = require("child_process")

function fatal(msg) {
    console.log("Fatal error:", msg)
    process.exit(1)
}

function main() {
    let mapFileName = process.argv[2]
    if (!mapFileName) {
        console.log("usage: node " + process.argv[1] + " build/mytarget/source/myprog.map")
        return
    }
    console.log("Map file: " + mapFileName)
    let mapFile = fs.readFileSync(mapFileName, "utf8")
    let addr = 0
    let logSize = 1024 * 4 + 4
    for (let ln of mapFile.split(/\r?\n/)) {
        let m = /^\s*0x00000([0-9a-f]+)\s+(\S+)/.exec(ln)
        if (m && m[2] == "codalLogStore") {
            addr = parseInt(m[1], 16)
            break
        }
    }
    if (!addr) fatal("Cannot find codalLogStore symbol in map file")

    let dirs = [
        process.env["HOME"] + "/Library/Arduino15",
        process.env["USERPROFILE"] + "/AppData/Local/Arduino15",
        process.env["HOME"] + "/.arduino15",
    ]

    let pkgDir = ""

    for (let d of dirs) {
        pkgDir = d + "/packages/arduino/"
        if (fs.existsSync(pkgDir)) break
        pkgDir = ""
    }

    if (!pkgDir) fatal("cannot find Arduino packages directory")

    let openocdPath = pkgDir + "tools/openocd/0.9.0-arduino/"
    if (!fs.existsSync(openocdPath)) fatal("openocd not installed in Arduino")

    let openocdBin = openocdPath + "bin/openocd"

    if (process.platform == "win32")
        openocdBin += ".exe"

    let zeroCfg = pkgDir + "hardware/samd/1.6.8/variants/arduino_zero/openocd_scripts/arduino_zero.cfg"
    let cmd = `init; set M(0) 0; mem2array M 8 ${addr} ${logSize}; parray M; exit`

    console.log("Starting openocd")
    child_process.execFile(openocdBin, ["-d2",
        "-s", openocdPath + "/share/openocd/scripts/",
        "-f", zeroCfg,
        "-c", cmd], {
            maxBuffer: 1 * 1024 * 1024,
        }, (err, stdout, stderr) => {
            if (err) {
                fatal("error: " + err.message)
            }
            let buf = new Buffer(logSize)
            for (let l of stdout.split(/\r?\n/)) {
                let m = /^M\((\d+)\)\s*=\s*(\d+)/.exec(l)
                if (m) {
                    buf[parseInt(m[1])] = parseInt(m[2])
                }
            }
            let len = buf.readUInt32LE(0)
            if (len == 0 || len > buf.length) {
                console.log(stderr)
                console.log("No logs.")
            } else {
                console.log("*\n* Logs\n*\n")
                console.log(buf.slice(4, 4 + len).toString("binary"))
            }
        })
}

main()