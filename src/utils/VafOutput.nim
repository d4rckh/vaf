import strformat

import ../types/VafFuzzResult

proc saveToFile*(response: VafFuzzResult, outFile: string): void = 
    let f = open(outFile, fmAppend)
    defer: f.close()
    f.writeLine(response.statusCode & ": " & response.url & &" (Length: {response.responseLength}; Time: {response.responseTime})") 