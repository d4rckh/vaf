import strformat
import strutils
import uri
import utils/VafResponse
import utils/VafLogger
import utils/VafHttpClient
import os
import argparse
import utils/VafFuzzResult
import utils/VafColors
import utils/VafBanner
import utils/VafOutput

printBanner()

let p = newParser("vaf"):
  option("-u", "--url", help="choose url, replace area to fuzz with []")
  option("-w", "--wordlist", help="choose the wordlist to use")
  option("-sc", "--status", default=some("200"), help="set on which status to print, set this param to 'any' to print on any status")
  option("-pr", "--prefix", default=some(""), help="prefix, e.g. set this to / for content discovery if your url doesnt have a / at the end")
  option("-sf", "--suffix", default=some(""), help="suffix, e.g. use this for extensions if you are doing content discovery")
  option("-pd", "--postdata", default=some("{}"), help="only used if '-m post' is set")
  option("-m", "--method", default=some("GET"), help="the method to use PSOT/GET")
  option("-g", "--grep", default=some(""), help="greps for a string in the response")
  option("-o", "--output", default=some(""), help="Output the results in a file")
  flag("-pif", "--printifreflexive", help="print only if the output reflected in the page, useful for finding xss")
  flag("-ue", "--urlencode", help="url encode the payloads")
  flag("-pu", "--printurl", help="prints the url that has been requested")

try:
    var parsedArgs = p.parse(commandLineParams())

    var url: string = parsedArgs.url
    var wordlist: string = parsedArgs.wordlist
    var printOnStatus: string = parsedArgs.status
    var requestMethod: string = parsedArgs.method.toUpper()
    var postData: string = parsedArgs.postdata
    var grep: string = parsedArgs.grep
    var displayPostData: string = postData.replace("[]", fmt"{resetcols}{orange}[]{resetcols}{khaki}")
    var displayUrl: string = url.replace("[]", fmt"{resetcols}{orange}[]{resetcols}{khaki}")

    if url == "" or wordlist == "":
        discard log("error", "Please specify an URL to fuzz using '-u' and a wordlist using '-w'.")
        quit(1)
    
    if not ( "[]" in url ) and ( requestMethod == "GET" ):
        discard log("error", "Please specify a fuzz area in the url, example: 'https://example.org/[]'")
        quit(1)
    if not ( ( "[]" in postData ) or ( "[]" in url ) ) and ( requestMethod == "POST" ):
        discard log("error", "Please specify a fuzz area in the post data or the url, example: '{\"username\": \"[]\"}' or 'https://example.org/[]'")
        quit(1)

    echo ""
    discard log("header", fmt"Argument summary")
    discard log("info", fmt"Printing on status: {khaki}{printOnStatus}")
    discard log("info", fmt"Target URL:         {khaki}{displayUrl}")
    if requestMethod == "POST":
        discard log("info", fmt"Post Data:          {khaki}{displayPostData}")
    discard log("info", fmt"Method:             {khaki}{requestMethod}")
    if not ( grep == "" ): 
        discard log("info", fmt"Grep:               {khaki}{grep}")
    discard log("info", fmt"Using Wordlist:     {khaki}{wordlist}")
    if not ( parsedArgs.prefix == ""):  
        discard log("info", fmt"Using prefixes:     {khaki}{parsedArgs.prefix}")
    if not ( parsedArgs.suffix == ""):  
        discard log("info", fmt"Using suffixes:     {khaki}{parsedArgs.suffix}")
    discard log("info", fmt"Print if reflexive: {khaki}{parsedArgs.printifreflexive}")
    discard log("info", fmt"Url Encode:         {khaki}{parsedArgs.urlencode}")
    # discard log("info", fmt"Print Url:          {khaki}{parsedArgs.printurl}")
    if not ( parsedArgs.output == ""):  
        discard log("info", fmt"Output file:        {khaki}{parsedArgs.output}")
    echo ""
    discard log("header", fmt"Results")
    for keyword in lines(wordlist):
        for prefix in parsedArgs.prefix.split(","):
            for suffix in parsedArgs.suffix.split(","):
                var word = prefix & keyword & suffix
                if parsedArgs.urlencode:
                    word = encodeUrl(word, true)
                var urlToRequest: string = url.replace("[]", word)
                var resp: VafResponse = makeRequest(urlToRequest, requestMethod, postData.replace("[]", word))
                var fuzzResult: VafFuzzResult = VafFuzzResult(
                    word: word, 
                    statusCode: resp.statusCode, 
                    urlencoded: parsedArgs.urlencode, 
                    url: urlToRequest, 
                    printUrl: parsedArgs.printurl, 
                    responseLength: resp.responseLength,
                    responseTime: resp.responseTime
                )
                proc doLog() = 
                    discard printResponse(fuzzResult)
                    if not ( parsedArgs.output == "" ):
                        saveTofile(fuzzResult, parsedArgs.output)

                if ((printOnStatus in resp.statusCode) or (printOnStatus == "any")) and (((word in resp.content) or decodeUrl(word) in resp.content) or not parsedArgs.printifreflexive) and (grep in resp.content):
                    doLog()
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(0)
