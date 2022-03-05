import VafColors
import VafFuzzResult
import strformat
import uri
import strutils

proc log*(logType: string, logMessage: string): int = 
    if logType == "info":
        echo aquamarine & "INFO: " & resetcols & logMessage & resetcols
        return 1
    if logType == "result":
        echo aquamarine & "RESULT: " & resetcols & logMessage  & resetcols
        return 1
    if logType == "header":
        echo bluey & "\t\t" & logMessage & resetcols & "\n"
        return 1
    if logType == "error":
        echo orange & "ERROR: " & logMessage & resetcols & "\n"


proc printResponse*(response: VafFuzzResult): int = 
    var urlDecoded: string = "" 
    var urlDisplay: string = ""
    var statusColor: string = khaki
    var statusCode: string = response.statusCode.split(" ")[0]
    if response.urlencoded:
        urlDecoded = "(" & decodeUrl(response.word) & ")"
    if response.printUrl:
        urlDisplay = response.url
        urlDisplay = urlDisplay.replace(response.word, fmt"{resetcols}{khaki}{response.word}{resetcols}{orange}")
    if "200" == statusCode or "201" == statusCode:
        statusColor = lightgreen
    return log("result", &"{resetcols}{statusColor}Status: {statusCode}; Length: {response.responseLength}\t{response.word} {orange}{urlDecoded} {urlDisplay} {resetcols}")
    