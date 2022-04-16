import strformat
import uri
import strutils
import httpclient

import VafColors
import ../types/[VafFuzzResult, VafFuzzArguments]

proc log*(logType: string, logMessage: string): void = 
    if logType == "info":
        echo &"{BLUEY}INFO: {RESETCOLS}{logMessage}{RESETCOLS}"
    if logType == "result":
        echo &"{BLUEY}RESULT: {RESETCOLS}{logMessage}{RESETCOLS}"
    if logType == "warn":
        echo &"{ORANGE}WARN: {RESETCOLS}{logMessage}{RESETCOLS}"
    if logType == "header":
        return
        # disable headers, they look ugly
        # echo &"{BLUEY}\t{logMessage}{RESETCOLS}\n"
    if logType == "error":
        echo &"{ORANGE}ERROR: {logMessage}{RESETCOLS}"
    if logType == "debug":
        echo &"{BLUEY}DEBUG: {logMessage}{RESETCOLS}"

proc log*(logType: string, logMessage: string, logArgument: string): void = 
    if logType == "option":
        echo &"{ORANGE}{logMessage}{RESETCOLS}: {logArgument}{RESETCOLS}"


proc printResponse*(fuzzResult: FuzzResult, fuzzArguments: FuzzArguments, threadId: int): void = 
    var urlDecoded = "" 
    var urlDisplay = ""
    var statusColor = KHAKI
    var statusCode = fuzzResult.statusCode.split(" ")[0]
    if fuzzResult.urlencoded:
        urlDecoded = &"({decodeUrl(fuzzResult.word)})"
    if fuzzResult.printUrl:
        urlDisplay = fuzzResult.url
        urlDisplay = urlDisplay.replace(fuzzResult.word, &"{RESETCOLS}{KHAKI}{fuzzResult.word}{RESETCOLS}{ORANGE}")
    if "200" == statusCode or "201" == statusCode:
        statusColor = LIGHTGREEN
    log("result", &"{RESETCOLS}{statusColor}[{fuzzResult.statusCode}] ({fuzzResult.response.responseLength} chars) {fuzzResult.response.responseTime}ms {fuzzResult.word} {ORANGE}{urlDecoded} {urlDisplay} {RESETCOLS}")    
    if fuzzArguments.detailedView:
        for key, val in fuzzResult.response.headers:
            echo &"| {ORANGE}{key}{RESETCOLS}: {val}"