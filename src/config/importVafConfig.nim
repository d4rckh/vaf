import json
import os
import strutils

import initVafConfig
import parseVafConfig

import VafConfigStructure

var homeDir: string = os.getHomeDir()

proc importVafConfig*(): VafConfigStructure = 
    var configExists: bool = fileExists(homedir & "/.vaf.json")
    var configContents = readFile(homedir & "/.vaf.json")
    var jsonData: JsonNode
 

    if configExists:
      jsonData = parseJson(configContents)
    # else:
    #   jsonData = initVafConfig()

    return parseVafConfig(jsonData)
    