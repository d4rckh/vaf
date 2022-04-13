import strformat
import uri
import strutils

import VafColors
import ../types/VafFuzzResult

proc log*(logType: string, logMessage: string): void = 
    if logType == "info":
        echo &"{AQUAMARINE}INFO: {RESETCOLS}{logMessage}{RESETCOLS}"
    if logType == "result":
        echo &"{AQUAMARINE}RESULT: {RESETCOLS}{logMessage}{RESETCOLS}"
    if logType == "header":
        echo &"{BLUEY}\t\t{logMessage}{RESETCOLS}"
    if logType == "error":
        echo &"{ORANGE}ERROR: {logMessage}{RESETCOLS}"
    if logType == "debug":
        echo &"{BLUEY}DEBUG: {logMessage}{RESETCOLS}"


proc printResponse*(response: FuzzResult, threadId: int): void = 
    var urlDecoded: string = "" 
    var urlDisplay: string = ""
    var statusColor: string = KHAKI
    var statusCode: string = response.statusCode.split(" ")[0]
    if response.urlencoded:
        urlDecoded = &"({decodeUrl(response.word)})"
    if response.printUrl:
        urlDisplay = response.url
        urlDisplay = urlDisplay.replace(response.word, &"{RESETCOLS}{KHAKI}{response.word}{RESETCOLS}{ORANGE}")
    if "200" == statusCode or "201" == statusCode:
        statusColor = LIGHTGREEN
    log("result", &"{RESETCOLS}{statusColor}[{response.statusCode}] ({response.responseLength} chars) {response.responseTime}ms\t{response.word} {ORANGE}{urlDecoded} {urlDisplay} {RESETCOLS}")    