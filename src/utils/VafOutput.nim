import strformat

import VafFuzzResult

proc saveToFile*(response: VafFuzzResult, outFile: string): void = 
    let f = open(outFile, fmAppend)
    defer: f.close()
    f.writeLine(response.statusCode & ": " & response.url & fmt" (Length: {response.responseLength}; Time: {response.responseTime})") 