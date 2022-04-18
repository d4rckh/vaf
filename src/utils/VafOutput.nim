import strformat

import ../types/VafFuzzResult

proc saveToFile*(fuzzResult: FuzzResult, outFile: string): void =
    let f = open(outFile, fmAppend)
    defer: f.close()
    f.writeLine(fuzzResult.statusCode & ": " & fuzzResult.url & &" (Length: {fuzzResult.response.responseLength}; Time: {fuzzResult.response.responseTime})") 