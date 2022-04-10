import VafColors
import VafFuzzResult
import strformat
import uri
import strutils

proc log*(logType: string, logMessage: string): void = 
    if logType == "info":
        echo AQUAMARINE & "INFO: " & RESETCOLS & logMessage & RESETCOLS
    if logType == "result":
        echo AQUAMARINE & "RESULT: " & RESETCOLS & logMessage  & RESETCOLS
    if logType == "header":
        echo BLUEY & "\t\t" & logMessage & RESETCOLS & "\n"
    if logType == "error":
        echo ORANGE & "ERROR: " & logMessage & RESETCOLS
    if logType == "debug":
        echo BLUEY & "DEBUG: " & logMessage & RESETCOLS


proc printResponse*(response: VafFuzzResult, threadId: int): void = 
    var urlDecoded: string = "" 
    var urlDisplay: string = ""
    var statusColor: string = KHAKI
    var statusCode: string = response.statusCode.split(" ")[0]
    if response.urlencoded:
        urlDecoded = "(" & decodeUrl(response.word) & ")"
    if response.printUrl:
        urlDisplay = response.url
        urlDisplay = urlDisplay.replace(response.word, fmt"{RESETCOLS}{KHAKI}{response.word}{RESETCOLS}{ORANGE}")
    if "200" == statusCode or "201" == statusCode:
        statusColor = LIGHTGREEN
    log("result", &"{RESETCOLS}{statusColor}Thread #{threadId}: Status: {statusCode}; Length: {response.responseLength}; Time: {response.responseTime}ms\t{response.word} {ORANGE}{urlDecoded} {urlDisplay} {RESETCOLS}")
    