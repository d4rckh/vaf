import strformat
import uri
import strutils
import httpclient
import terminal

import VafColors
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


proc log*(logType: string, logMessage: string, logArgument: string): void = 
    if logType == "option":
        stdout.styledWriteLine(
            fgCyan, logMessage, fgWhite, ": ", logArgument, fgWhite
        )

proc printResponse*(fuzzResult: FuzzResult, fuzzArguments: FuzzArguments, threadId: int): void = 
    var urlDecoded = "" 
    var urlDisplay = ""
    var statusColor = fgYellow
    var statusCode = fuzzResult.statusCode.split(" ")[0]
    if fuzzResult.urlencoded:
        urlDecoded = &"({decodeUrl(fuzzResult.word)})"
    if fuzzResult.printUrl:
        urlDisplay = fuzzResult.url
        urlDisplay = urlDisplay.replace(fuzzResult.word, &"{fgWhite}{fgYellow}{fuzzResult.word}{fgWhite}{fgYellow}")
    if parseInt(statusCode) in {200 .. 299}:
        statusColor = fgGreen
    # its khaki by default
    # if parseInt(statusCode) in {300 .. 399}:
    #     statusColor = KHAKI
    if parseInt(statusCode) in {400 .. 499}:
        statusColor = fgRed
    
    stdout.styledWriteLine(
        # Status
        statusColor, &"[{fuzzResult.statusCode}] ",
        # Length
        &"({fuzzResult.response.responseLength}c) ",
        # Time,
        &"{fuzzResult.response.responseTime}ms ",
        # Word,
        &"{fuzzResult.word} {urlDecoded} {urlDisplay}",
        fgWhite
    )

    # log("result", &"{RESETCOLS}{statusColor}[{fuzzResult.statusCode}] ({fuzzResult.response.responseLength} chars) {fuzzResult.response.responseTime}ms {fuzzResult.word} {ORANGE}{urlDecoded} {urlDisplay} {RESETCOLS}")    
    if fuzzArguments.printheaders:
        for key, val in fuzzResult.response.headers:
            stdout.styledWriteLine("| ", fgMagenta, key, fgWhite, ": ", val)