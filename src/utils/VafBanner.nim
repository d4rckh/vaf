import strformat

import VafCompileConsts

proc printBanner*(): void =
  echo fmt""" 
                     _____ 
      ___  _______ _/ ____\
      \  \/ /\__  \\   __\ 
       \   /  / __ \|  |    
        \_/  (____  /__|   
                  \/ {TAG}
            https://github.com/d4rckh/vaf  
"""