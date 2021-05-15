import json
import os
import strutils

import VafWordlist
import VafConfigStructure

proc parseWordlist(data: JsonNode): VafWordlist = 
  var wordlistObject: VafWordlist = VafWordlist()

  if data{"Id"} != nil:
    wordlistObject.Id = data{"Id"}.getInt()

  if data{"Path"} != nil:
    wordlistObject.Path = data{"Path"}.getStr()

  return wordlistObject

proc parseVafConfig*(data: JsonNode): VafConfigStructure = 
  var configObject: VafConfigStructure = VafConfigStructure()

  echo data

  if data{"DefaultWordlist"} == nil:
    configObject.DefaultWordlist = -1
  else:
    configObject.DefaultWordlist = data{"DefaultWordlist"}.getInt()

  if data{"Wordlists"} != nil:
    for wordlist in data{"Wordlists"}:
      configObject.Wordlists.add( parseWordlist( wordlist ))
    

  echo configObject

  return configObject