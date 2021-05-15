import json
import os
import strutils
import initVafConfig

var homeDir: string = os.getHomeDir()

proc readVafConfig*(): int = 
    var configExists: bool = fileExists(homedir & "/.vaf.json")
    var configContents = readFile(homedir & "/.vaf.json")
    var jsonNode = parseJson(configContents)

    discard initVafConfig()

    if configExists:
        return 0
    else:
        echo jsonNode