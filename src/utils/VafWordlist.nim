import std/streams
import os
import strformat
import strutils
import uri

import VafFuzzArguments

proc prepareWordlist*(fuzzArguments: VafFuzzArguments) =
    let wordlistFile = fuzzArguments.wordlistFile
    let prefixes = fuzzArguments.prefixes
    let suffixes = fuzzArguments.suffixes
    let urlencode = fuzzArguments.urlencode
    
    var strm = newFileStream(wordlistFile, fmRead)
    var line = ""

    if not isNil(strm):
        while strm.readLine(line):
            for prefix in prefixes:
                for suffix in suffixes:
                    var word = prefix & line & suffix
                    if urlencode:
                        word = encodeUrl(word, true)
                    echo word

    strm.close()