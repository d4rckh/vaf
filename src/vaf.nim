import system
import strformat
import strutils
import uri
import httpclient
import os
import argparse
import std/streams

import utils/VafResponse
import utils/VafLogger
import utils/VafHttpClient
import utils/VafFuzzResult
import utils/VafFuzzArguments
import utils/VafColors
import utils/VafBanner
import utils/VafOutput
import utils/VafThreadArguments
import utils/VafWordlist
import utils/VafCompileConsts

printBanner()

let p = newParser("vaf"):
  option("-u", "--url", help="choose url, replace area to fuzz with []")
  option("-w", "--wordlist", help="choose the wordlist to use")
  option("-sc", "--status", default=some("200"), help="set on which status to print, set this param to 'any' to print on any status")
  option("-pf", "--prefix", default=some(""), help="prefix, e.g. set this to / for content discovery if your url doesnt have a / at the end")
  option("-sf", "--suffix", default=some(""), help="suffix, e.g. use this for extensions if you are doing content discovery")
  option("-pd", "--postdata", default=some("{}"), help="only used if '-m post' is set")
  option("-m", "--method", default=some("GET"), help="the method to use PSOT/GET")
  option("-g", "--grep", default=some(""), help="greps for a string in the response")
  option("-o", "--output", default=some(""), help="Output the results in a file")
  option("-t", "--threads", default=some("1"), help="The amount of threads to use")
  flag("-v", "--version", help="get version information")
  flag("-pif", "--printifreflexive", help="print only if the output reflected in the page, useful for finding xss")
  flag("-ue", "--urlencode", help="url encode the payloads")
  flag("-pu", "--printurl", help="prints the url that has been requested")
  flag("-dbg", "--debug", help="Prints a lot of debug information")

try:
    var parsedArgs = p.parse(commandLineParams())

    if parsedArgs.version:
        echo fmt"vaf {TAG}@{BRANCH} compiled on {PLATFORM} at {CompileTime} {CompileDate}"
        quit(QuitSuccess)
    
    var url: string = parsedArgs.url
    var wordlist: string = parsedArgs.wordlist
    var printOnStatus: string = parsedArgs.status
    var requestMethod: string = parsedArgs.method.toUpper()
    var postData: string = parsedArgs.postdata
    var grep: string = parsedArgs.grep
    var displayPostData: string = postData.replace("[]", fmt"{RESETCOLS}{ORANGE}[]{RESETCOLS}{KHAKI}")
    var displayUrl: string = url.replace("[]", fmt"{RESETCOLS}{ORANGE}[]{RESETCOLS}{KHAKI}")

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
    log("info", fmt"Printing on status: {KHAKI}{printOnStatus}")
    log("info", fmt"Target URL:         {KHAKI}{displayUrl}")
    if requestMethod == "POST":
        log("info", fmt"Post Data:          {KHAKI}{displayPostData}")
    log("info", fmt"Method:             {KHAKI}{requestMethod}")
    if not ( grep == "" ): 
        log("info", fmt"Grep:               {KHAKI}{grep}")
    log("info", fmt"Using Wordlist:     {KHAKI}{wordlist}")
    if not ( parsedArgs.prefix == ""):  
        log("info", fmt"Using prefixes:     {KHAKI}{parsedArgs.prefix}")
    if not ( parsedArgs.suffix == ""):  
        log("info", fmt"Using suffixes:     {KHAKI}{parsedArgs.suffix}")
    log("info", fmt"Print if reflexive: {KHAKI}{parsedArgs.printifreflexive}")
    log("info", fmt"Url Encode:         {KHAKI}{parsedArgs.urlencode}")
    if not ( parsedArgs.output == ""):  
        log("info", fmt"Output file:        {KHAKI}{parsedArgs.output}")
    echo ""
    log("header", fmt"Results")
    
    proc fuzz(word: string, client: HttpClient, args: VafFuzzArguments, threadId: int): void =
        var urlToRequest: string = args.url.replace("[]", word)
        var resp: VafResponse = makeRequest(urlToRequest, args.requestMethod, args.postData.replace("[]", word), client)
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
            printResponse(fuzzResult, threadId)
            if not (args.output == ""):
                saveTofile(fuzzResult, args.output)

        if  ((args.printOnStatus in resp.statusCode) or (args.printOnStatus == "any")) and 
            (((word in resp.content) or decodeUrl(word) in resp.content) or not args.printifreflexive) and 
            (args.grep in resp.content):
            doLog()

    let prefixes = parsedArgs.prefix.split(",")
    let suffixes = parsedArgs.suffix.split(",")

    var fuzzData: VafFuzzArguments = VafFuzzArguments(
        url: url,
        grep: grep,
        printOnStatus: printOnStatus,
        postData: postData,
        requestMethod: requestMethod,
        urlencode: parsedArgs.urlencode,
        wordlistFile: wordlist,
        suffixes: suffixes,
        prefixes: prefixes,
        printurl: parsedArgs.printurl,
        threadcount: parseInt(parsedArgs.threads),
        output: parsedArgs.output,
        printifreflexive: parsedArgs.printifreflexive,
        debug: parsedArgs.debug
    )

    let wordlistFiles: seq[string] = prepareWordlist(fuzzData)

    var
        threadCount = len(wordlistFiles)
        threads = newSeq[Thread[tuple[threadId: int, threadArguments: VafThreadArguments]]](threadCount)

    proc threadFunction(data: tuple[threadId: int, threadArguments: VafThreadArguments]) {.thread.} =
        var client: HttpClient = newHttpClient()
        var threadData: VafThreadArguments = data.threadArguments
        
        if threadData.fuzzData.debug:
            echo "ThreadID: " & $data.threadId & " | got to deal with the " & threadData.wordlistFile & " wordlist"

        var strm = newFileStream(threadData.wordlistFile, fmRead)
        var line = ""
        if not isNil(strm):
            while strm.readLine(line):
                if threadData.fuzzData.debug:
                    log("debug", "ThreadID: " & $data.threadId & " | " & " fuzzing w/ " & line)
                fuzz(line, client, threadData.fuzzData, data.threadId)
        strm.close()

    var i = 0
    for thread in threads.mitems:
        if parsedArgs.debug:
            log("debug", "Creating thread with ID " & $i)
        var threadArguments: VafThreadArguments = VafThreadArguments(
            fuzzData: fuzzData,
            wordlistFile: wordlistFiles[i] 
        )
        createThread(thread, threadFunction, (i, threadArguments))
        i += 1  

    joinThreads(threads)
    cleanWordlists(wordlistFiles)
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(0)