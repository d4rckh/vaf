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

let p = newParser("vaf - very advanced fuzzer"):
  option("-u", "--url", help="choose url, replace area to fuzz with []")
  option("-w", "--wordlist", help="choose the wordlist to use")
  option("-sc", "--status", default=some("200"), help="set on which status to print, set this param to 'any' to print on any status")
  option("-pr", "--prefix", default=some(""), help="prefix, e.g. set this to / for content discovery if your url doesnt have a / at the end")
  option("-sf", "--suffix", default=some(""), help="suffix, e.g. use this for extensions if you are doing content discovery")
  option("-pd", "--postdata", default=some("{}"), help="only used if '-m post' is set")
  option("-m", "--method", default=some("get"), help="suffix, e.g. use this for extensions if you are doing content discovery")
  flag("-pif", "--printifreflexive", help="print only if the output reflected in the page, useful for finding xss")
  flag("-ue", "--urlencode", help="url encode the payloads")
  flag("-pu", "--printurl", help="prints the url that has been requested")

try:
    var parsedArgs = p.parse(commandLineParams())

    var url: string = parsedArgs.url
    var wordlist: string = parsedArgs.wordlist
    var printOnStatus: string = parsedArgs.status
    var requestMethod: string = parsedArgs.method
    var postData: string = parsedArgs.postdata
    var displayPostData: string = postData.replace("[]", fmt"{resetcols}{orange}[]{resetcols}{khaki}")
    var displayUrl: string = url.replace("[]", fmt"{resetcols}{orange}[]{resetcols}{khaki}")

    echo ""
    discard log("header", fmt"Argument summary:")
    discard log("info", fmt"Printing on status: {khaki}{printOnStatus}")
    discard log("info", fmt"Target URL:         {khaki}{displayUrl}")
    discard log("info", fmt"Post Data:          {khaki}{displayPostData}")
    discard log("info", fmt"Method:             {khaki}{requestMethod}")
    discard log("info", fmt"Using Wordlist:     {khaki}{wordlist}")
    discard log("info", fmt"Using prefixes:     {khaki}{parsedArgs.prefix}")
    discard log("info", fmt"Using suffixes:     {khaki}{parsedArgs.suffix}")
    discard log("info", fmt"Print if reflexive: {khaki}{parsedArgs.printifreflexive}")
    discard log("info", fmt"Url Encode:         {khaki}{parsedArgs.urlencode}")
    discard log("info", fmt"Print Url:          {khaki}{parsedArgs.printurl}")
    echo ""
    discard log("header", fmt"Results:")
    for keyword in lines(wordlist):
        for prefix in parsedArgs.prefix.split(","):
            for suffix in parsedArgs.suffix.split(","):
                var word = prefix & keyword & suffix
                if parsedArgs.urlencode:
                    word = encodeUrl(word, true)
                var urlToRequest: string = url.replace("[]", word)
                var resp: VafResponse = makeRequest(urlToRequest, requestMethod, postData.replace("[]", word))

                proc doLog() = 
                    discard printResponse(VafFuzzResult(word: word, statusCode: resp.statusCode, urlencoded: parsedArgs.urlencode, url: urlToRequest, printUrl: parsedArgs.printurl, responseLength: resp.responseLength))

                if ((printOnStatus in resp.statusCode) or (printOnStatus == "any")) and (((word in resp.content) or decodeUrl(word) in resp.content) or not parsedArgs.printifreflexive):
                    doLog()
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(0)
