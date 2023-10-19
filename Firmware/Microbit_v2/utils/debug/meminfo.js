#!/usr/bin/env node
"use strict";

function main() {
    let fs = require("fs");
    let mfn = process.argv[2]
    if (!mfn) {
        console.log("usage: node " + process.argv[1] + " build/mytarget/source/myprog.map")
        return
    }
    console.log("Map file: " + mfn)
    let map = fs.readFileSync(mfn, "utf8")
    let inSect = 0
    let byFileRAM = {}
    let byFileROM = {}
    for (let ln of map.split(/\r?\n/)) {
        if (ln == "Linker script and memory map") {
            inSect = 1
        }
        if (/^OUTPUT\(/.test(ln)) {
            inSect = 2
        }
        if (inSect == 1) {
            let m = /^\s*(\S*)\s+0x00000([0-9a-f]+)\s+0x([0-9a-f]+)\s+(\S+)/.exec(ln)
            if (m) {
                let mark = m[1]
                if (mark == "*fill*" || mark == ".bss" || mark == ".relocate")
                    continue;
                let addr = parseInt(m[2], 16)
                let sz = parseInt(m[3], 16)
                let fn = m[4]
                if (fn == "load" && mark) fn = mark;
                fn = fn.replace(/.*armv6-m/, "")
                if (sz) {
                    let mm = addr < 0x10000000 ? byFileROM : byFileRAM
                    mm[fn] = (mm[fn] || 0) + sz
                }
            }
        }
    }

    console.log("*\n* ROM\n*")
    dumpMap(byFileROM)
    console.log("*\n* RAM\n*")
    dumpMap(byFileRAM)
}

function printEnt(sz, s) {
    let ff = ("        " + sz).slice(-7)
    console.log(ff + "  " + s)
}

function dumpMap(m) {
    let k = Object.keys(m)
    k.sort((a, b) => m[a] - m[b])
    let sum = 0
    for (let s of k) {
        printEnt(m[s], s)
        sum += m[s]
    }
    printEnt(sum, "TOTAL")
}


main()