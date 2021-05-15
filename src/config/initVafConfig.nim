import os
import strutils

var homeDir: string = os.getHomeDir()
var defaultJson: string = """{}"""

proc initVafConfig*(): int = 
    var configExists: bool = fileExists(homedir & "/.vaf.json")
    var configFile = open(homedir & "/.vaf.json", fmWrite)
    
    defer: configFile.close()
    
    if configExists:
        return 1
    else:
        for i in defaultJson.split("\n"):
            configFile.writeLine(i)