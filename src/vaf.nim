import system
import strformat
import strutils
import uri
import httpclient
import argparse
import net
import std/[streams, terminal, os, times]

import types/[VafFuzzResponse, VafFuzzResult, VafThreadArguments, VafFuzzArguments]

import utils/VafLogger
import utils/VafHttpClient
import utils/VafColors
import utils/VafBanner
import utils/VafOutput
import utils/VafWordlist
import utils/VafCompileConsts

import utils/formatDuration

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
  option("-t", "--threads", default=some("5"), help="The amount of threads to use")
  option("-x", "--proxy", default=some(""), help="the proxy to use")
  option("-ca", "--cafile", default=some(""), help="specify a root certificate to use")
  flag("-v", "--version", help="get version information")
  flag("-pif", "--printifreflexive", help="print only if the output reflected in the page, useful for finding xss")
  flag("-i", "--ignoressl", help="do not very ssl certificates")
  flag("-ue", "--urlencode", help="url encode the payloads")
  flag("-pu", "--printurl", help="prints the url that has been requested")
  flag("-d", "--detailed", help="prints more info the about the requests like it's response headers")
  flag("-dbg", "--debug", help="Prints a lot of debug information")

try:
    let parsedArgs = p.parse(commandLineParams())

    if parsedArgs.version:
        echo &"vaf {TAG}@{BRANCH} compiled on {PLATFORM} at {CompileTime} {CompileDate}"

        quit(QuitSuccess)

    let url: string = parsedArgs.url
    let wordlist: string = parsedArgs.wordlist
    let printOnStatus: seq[string] = map(parsedArgs.status.split(","), proc(x: string): string = x.strip)
    let requestMethod: string = parsedArgs.method.toUpper()
    let postData: string = parsedArgs.postdata
    let grep: string = parsedArgs.grep
    let displayPostData: string = postData.replace("[]", &"{RESETCOLS}{ORANGE}[]{RESETCOLS}{KHAKI}")
    let displayUrl: string = url.replace("[]", &"{RESETCOLS}{ORANGE}[]{RESETCOLS}{KHAKI}")

    var options: seq[string] = @[]
    if parsedArgs.printifreflexive:
        options.add("Print if reflexive")
    if parsedArgs.urlencode:
        options.add("URL encode")

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

    log("header", "Argument summary")
    log("option", "Target", displayUrl)
    log("option", "Method", requestMethod)
    log("option", "Status", printOnStatus.join(", "))
    log("option", "Threads", parsedArgs.threads)
    if requestMethod == "POST":
        log("option", "Post Data", displayPostData)
    if not ( grep == "" ): 
        log("option", "Grep", grep)
    log("option", "Wordlist", wordlist)
    if not ( parsedArgs.prefix == ""):  
        log("option", "Prefixes", parsedArgs.prefix)
    if not ( parsedArgs.suffix == ""):  
        log("option", "Suffixes", parsedArgs.suffix)
    if parsedArgs.proxy != "":
        log("option", "Proxy", parsedArgs.proxy)
    if len(options) != 0:
        log("option", "Options", options.join(", "))
    # log("info", &"Print if reflexive: {KHAKI}{parsedArgs.printifreflexive}")
    # log("info", &"Url Encode:         {KHAKI}{parsedArgs.urlencode}")
    if not ( parsedArgs.output == ""):  
        log("option", "Output", parsedArgs.output)
    echo ""
    
    var chan: Channel[(FuzzResult, FuzzResponse, int)]
    chan.open()

    proc fuzz(word: string, client: HttpClient, args: FuzzArguments, threadId: int): void =
        let urlToRequest: string = args.url.replace("[]", word)
        let resp: FuzzResponse = makeRequest(urlToRequest, args.requestMethod, args.postData.replace("[]", word), client)
        let fuzzResult: FuzzResult = FuzzResult(
            word: word, 
            statusCode: resp.statusCode, 
            urlencoded: args.urlencode, 
            url: urlToRequest, 
            printUrl: args.printurl, 
            response: resp
        )
    
        chan.send((fuzzResult, resp, threadId))

    let prefixes = parsedArgs.prefix.split(",")
    let suffixes = parsedArgs.suffix.split(",")

    let fuzzData: FuzzArguments = FuzzArguments(
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
        debug: parsedArgs.debug,
        detailedView: parsedArgs.detailed,
        proxy: parsedArgs.proxy,
        caFile: parsedArgs.cafile,
        ignoreSSL: parsedArgs.ignoressl
    )

    let (wordlistFiles, wordlistsSize) = prepareWordlist(fuzzData)
    
    echo ""
    
    let threadCount = len(wordlistFiles)
    var threads = newSeq[Thread[tuple[threadId: int, threadArguments: ThreadArguments]]](threadCount)

    proc threadFunction(data: tuple[threadId: int, threadArguments: ThreadArguments]) {.thread.} =
        let threadData: ThreadArguments = data.threadArguments
        var verifyMode = CVerifyPeer
        if threadData.fuzzData.ignoreSSL:
            verifyMode= CVerifyNone
        let sslContext: SslContext = newContext(caFile=threadData.fuzzData.caFile, verifyMode=verifyMode)
        var proxy: Proxy = nil
        if threadData.fuzzData.proxy != "":
            proxy = newProxy(threadData.fuzzData.proxy)
        let client: HttpClient = newHttpClient(sslContext=sslContext, proxy=proxy)
        
        if threadData.fuzzData.debug:
            echo "ThreadID: " & $data.threadId & " | got to deal with the " & threadData.wordlistFile & " wordlist"

        let strm = newFileStream(threadData.wordlistFile, fmRead)
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
        var threadArguments: ThreadArguments = ThreadArguments(
            fuzzData: fuzzData,
            wordlistFile: wordlistFiles[i] 
        )
        createThread(thread, threadFunction, (i, threadArguments))
        i += 1  

    var fuzzProgress = 0
    var fuzzPercentage = 0
    let timeStarted = now()

    log("header", &"Results")

    while true:

        let tried = chan.tryRecv()
        if tried.dataAvailable:

            let (fuzzResult, resp, threadId) = tried.msg
            let s: int = len(filter(printOnStatus, proc(x: string): bool = x in resp.statusCode))
            
            if  ((s > 0) or 
                (printOnStatus[0] == "any")) and 
                (((fuzzResult.word in resp.content) or decodeUrl(fuzzResult.word) in resp.content) or 
                not parsedArgs.printifreflexive) and 
                (parsedArgs.grep in resp.content):
                
                printResponse(fuzzResult, fuzzData, threadId)
            
            if not (parsedArgs.output == ""):
                saveTofile(fuzzResult, parsedArgs.output)

            inc fuzzProgress
            fuzzPercentage = (fuzzProgress / wordlistsSize * 100).int

            if fuzzProgress == wordlistsSize:
                break

        stdout.styledWriteLine(
            fgWhite, "Progress: ", fgRed, 
            "0% ", 
            fgWhite, 
            '#'.repeat (fuzzPercentage/10).int, '-'.repeat (10 - (fuzzPercentage/10).int), 
            fgYellow, " ", 
            $fuzzPercentage, 
            "% ", fgWhite, "Time: ", fgYellow, formatDuration(now() - timeStarted))

        cursorUp 1
        eraseLine()

    joinThreads(threads)
    
    echo ""
    log("info", &"Finished in {formatDuration(now() - timeStarted)}")


    cleanWordlists(wordlistFiles)
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    quit(0)