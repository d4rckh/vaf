import strformat
import uri
import strutils
import httpclient
import terminal

import ../types/[VafFuzzResult, VafFuzzArguments]

proc log*(logType: string, logMessage: string): void = 
    if logType == "info":
        stdout.styledWriteLine(
            fgBlue, "[INFO] ", logMessage, fgWhite
        )
    if logType == "result":
        stdout.styledWriteLine(
            fgGreen, "[RESULT] ", logMessage, fgWhite
        )
    if logType == "warn":
        stdout.styledWriteLine(
            fgYellow, "[WARN] ", logMessage, fgWhite
        )
    if logType == "header":
        return
        # disable headers, they look ugly
        # echo &"{BLUEY}\t{logMessage}{RESETCOLS}\n"
    if logType == "error":
        stdout.styledWriteLine(
            fgRed, "[ERROR] ", logMessage, fgWhite
        )    
    if logType == "debug":
        stdout.styledWriteLine(
            fgBlue, "[DEBUG] ", logMessage, fgWhite
        )

proc highlightSth*(message: string, what: string, color: ForegroundColor) = 
    let parts = message.split(what)
    var i = 0
    for part in parts:
        stdout.styledWrite(part)
        if i < (len(parts) - 1):
            stdout.styledWrite(color, what, fgWhite)
        inc i

proc log*(logType: string, logMessage: string, logArgument: string): void = 
    if logType == "option":
        stdout.styledWrite(fgCyan, logMessage, fgWhite, ": ")
        if logMessage in @["Target", "Post Data"]:
            highlightSth(logArgument, "FUZZ", fgYellow)
            echo ""
        else:
            stdout.styledWriteLine(logArgument) 

proc printResponse*(fuzzResult: FuzzResult, fuzzArguments: FuzzArguments, threadId: int): void = 
    var wordDecoded = "" 
    var statusColor = fgYellow
    var statusCode = fuzzResult.statusCode.split(" ")[0]
    if fuzzResult.urlencoded:
        wordDecoded = &"({decodeUrl(fuzzResult.word)})"
    if parseInt(statusCode) in {200 .. 299}:
        statusColor = fgGreen
    if parseInt(statusCode) in {300 .. 399}:
        statusColor = fgGreen
    if parseInt(statusCode) in {400 .. 499}:
        statusColor = fgRed
    
    stdout.styledWrite(
        # Status
        statusColor, &"[{fuzzResult.statusCode}] ",
        # Length
        &"({fuzzResult.response.responseLength}c) ",
        # Time,
        &"{fuzzResult.response.responseTime}ms ",
        # Word,
        &"{fuzzResult.word} {wordDecoded} ",
        fgWhite
    )

    if fuzzResult.printurl:
        highlightSth(fuzzResult.url, fuzzResult.word, fgYellow)
    echo ""

    # log("result", &"{RESETCOLS}{statusColor}[{fuzzResult.statusCode}] ({fuzzResult.response.responseLength} chars) {fuzzResult.response.responseTime}ms {fuzzResult.word} {ORANGE}{urlDecoded} {urlDisplay} {RESETCOLS}")    
    if fuzzArguments.printheaders:
        for key, val in fuzzResult.response.headers:
            stdout.styledWriteLine("| ", fgMagenta, key, fgWhite, ": ", val)