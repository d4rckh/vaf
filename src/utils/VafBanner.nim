import strformat

import VafCompileConsts

proc printBanner*(): void =
  echo &""" 
                     _____ 
      ___  _______ _/ ____\
      \  \/ /\__  \\   __\ 
       \   /  / __ \|  |    
        \_/  (____  /__|   
                  \/ {TAG}
            https://github.com/d4rckh/vaf  
"""

# proc printBanner*(): void =
#   echo &"\nvaf {TAG} https://github.com/d4rckh/vaf"