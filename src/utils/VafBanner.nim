import strformat
import random

import VafCompileConsts

const BANNERS: seq[string] = @[

"""                     _____ 
      ___  _______ _/ ____\
      \  \/ /\__  \\   __\ 
       \   /  / __ \|  |    
        \_/  (____  /__|   
                  \/"""

]

proc printBanner*(): void =
  randomize()
  echo &""" 
{sample(BANNERS)} {TAG}
            https://github.com/d4rckh/vaf"""