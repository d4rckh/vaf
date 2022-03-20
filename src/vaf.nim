import strformat
import strutils
import uri
import utils/VafResponse
import utils/VafLogger
import utils/VafHttpClient
import os
import argparse
import utils/VafFuzzResult
import utils/VafFuzzArguments
import utils/VafColors
import utils/VafBanner
import utils/VafOutput
import utils/VafThreadArguments
import std/streams
import std/locks
import math


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
        log("error", "Please specify an URL to fuzz using '-u' and a wordlist using '-w'.")
        quit(1)

    if not os.fileExists(wordlist):
        log("error", "File " & wordlist & " does not exist.")
        quit(1)
    
    if not ("[]" in url) and (requestMethod == "GET"):
        log("error", "Please specify a fuzz area in the url, example: 'https://example.org/[]'")
        quit(1)

    if not (("[]" in postData) or ("[]" in url)) and (requestMethod == "POST"):
        log("error", "Please specify a fuzz area in the post data or the url, example: '{\"username\": \"[]\"}' or 'https://example.org/[]'")
        quit(1)

    echo ""
    log("header", fmt"Argument summary")
    log("info", fmt"Printing on status: {khaki}{printOnStatus}")
    log("info", fmt"Target URL:         {khaki}{displayUrl}")
    if requestMethod == "POST":
        log("info", fmt"Post Data:          {khaki}{displayPostData}")
    log("info", fmt"Method:             {khaki}{requestMethod}")
    if not ( grep == "" ): 
        log("info", fmt"Grep:               {khaki}{grep}")
    log("info", fmt"Using Wordlist:     {khaki}{wordlist}")
    if not ( parsedArgs.prefix == ""):  
        log("info", fmt"Using prefixes:     {khaki}{parsedArgs.prefix}")
    if not ( parsedArgs.suffix == ""):  
        log("info", fmt"Using suffixes:     {khaki}{parsedArgs.suffix}")
    log("info", fmt"Print if reflexive: {khaki}{parsedArgs.printifreflexive}")
    log("info", fmt"Url Encode:         {khaki}{parsedArgs.urlencode}")
    if not ( parsedArgs.output == ""):  
        log("info", fmt"Output file:        {khaki}{parsedArgs.output}")
    echo ""
    log("header", fmt"Results")
    
    proc fuzz(word: string, client: HttpClient, args: VafFuzzArguments): void =
        var urlToRequest: string = args.url.replace("[]", word)
        var resp: VafResponse = makeRequest(urlToRequest, args.requestMethod, args.postData.replace("[]", word))
        var fuzzResult: VafFuzzResult = VafFuzzResult(
            word: word, 
            statusCode: resp.statusCode, 
            urlencoded: args.urlencode, 
            url: urlToRequest, 
            printUrl: args.printurl, 
            responseLength: resp.responseLength,
            responseTime: resp.responseTime
        )
        proc doLog() = 
            printResponse(fuzzResult)
            if not (args.output == ""):
                saveTofile(fuzzResult, args.output)

        if  ((args.printOnStatus in resp.statusCode) or (args.printOnStatus == "any")) and 
            (((word in resp.content) or decodeUrl(word) in resp.content) or not args.printifreflexive) and 
            (args.grep in resp.content):
            doLog()

    # var strm = newFileStream(wordlist, fmRead)
    var line = ""

    let prefixes = parsedArgs.prefix.split(",")
    let suffixes = parsedArgs.suffix.split(",")

    var
        wordCount = 10 
        threadCount = 5
        threads = newSeq[Thread[tuple[threadId, startIndex, endIndex: int, fuzzData: VafFuzzArguments]]](threadCount)
        L: Lock
        wordCountPerThread = math.floorDiv(wordCount, threadCount)
        remainingWordCount = wordCount mod threadCount
        fileLines = readFile(wordlist).split("\n")

    echo "wordCount: " & $wordCount
    echo "threadCount: " & $threadCount
    echo "wordCountPerThread: " & $wordCountPerThread
    echo "remainingWordCount: " & $remainingWordCount

    proc threadFunction(data: tuple[threadId, startIndex, endIndex: int, fuzzData: VafFuzzArguments]) {.thread.} =
        var client: HttpClient = newHttpClient()
        echo "ThreadID: " & $data.threadId & " | Indexes: " & $data.startIndex & " -> " & $data.endIndex
        for i in data.startIndex..data.endIndex:
            echo "ThreadID: " & $data.threadId & " | " & $i
        fuzz("index.html/#" & $data.threadId, client, data.fuzzData)

    var i = 0
    for thread in threads.mitems:
        var startIndex = i*wordCountPerThread
        var endIndex = i*wordCountPerThread+wordCountPerThread-1
        if i == threadCount-1:
            endIndex += remainingWordCount
        var fuzzData: VafFuzzArguments = VafFuzzArguments(
            url: url,
            grep: grep,
            printOnStatus: printOnStatus,
            postData: postData,
            requestMethod: requestMethod,
            urlencode: parsedArgs.urlencode,
            printurl: parsedArgs.printurl,
            output: parsedArgs.output,
            printifreflexive: parsedArgs.printifreflexive
        )

        createThread(thread, threadFunction, (i,startIndex,endIndex,fuzzData))
        i += 1

    joinThreads(threads)

    # if not isNil(strm):
    #     while strm.readLine(line):
    #         for prefix in prefixes:
    #             for suffix in suffixes:
    #                 var word = prefix & line & suffix
    #                 if parsedArgs.urlencode:
    #                     word = encodeUrl(word, true)
    #                 fuzz(word)
    #     strm.close()

except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(0)