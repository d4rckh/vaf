import os
import strformat
import uri
import std/[streams, times]
import ../types/VafFuzzArguments

import VafUtils
import VafLogger

proc cleanWordlists*(wordlistFiles: seq[string]) =
    log("info", "Cleaning up...")
    for wordlist in wordlistFiles:
        removeFile(wordlist)

proc prepareWordlist*(fuzzArguments: FuzzArguments): (seq[string], int) =
    let wordlistFile = fuzzArguments.wordlistFile
    let prefixes = fuzzArguments.prefixes
    let suffixes = fuzzArguments.suffixes
    let urlencode = fuzzArguments.urlencode
    let threadcount = fuzzArguments.threadCount
    let tempdir = getTempDir()

    if fuzzArguments.debug:
        log("debug", &"Storing temporary wordlists in temp dir: {tempdir}")

    let x = now().format("yyyyMMddhhmmss")
    var wordlistStreams: seq[File] = @[]
    var threadWordlists: seq[string] = @[]

    for tid in countTo(threadcount - 1):
        let fn = &"{tempdir}/vaf{x}_thread{tid}.txt"
        wordlistStreams.add(open(fn, fmAppend))
        threadWordlists.add(fn)

    var strm = newFileStream(wordlistFile, fmRead)
    var line = ""
    var i = 0
    var wordlistsSize = 0

    log("info", &"Loading wordlist...")

    if not isNil(strm):
        while strm.readLine(line):
            for prefix in prefixes:
                for suffix in suffixes:
                    var word = newStringOfCap(prefix.len + line.len + suffix.len)
                    word.add(prefix)
                    word.add(line)
                    word.add(suffix)
                    if urlencode:
                        word = encodeUrl(word, true)
                    wordlistStreams[i].writeLine(word)
                    inc wordlistsSize
            inc i
            if i == threadcount:
                i = 0

    # close streams
    strm.close()
    for stream in wordlistStreams:
        stream.close()
    
    return (threadWordlists, wordlistsSize)