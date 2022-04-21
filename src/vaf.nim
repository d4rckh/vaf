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
import utils/VafBanner
import utils/VafOutput
import utils/VafWordlist
import utils/VafCompileConsts
import utils/VafUtils

printBanner()

type
  VafError = enum
    VafSSLVerificationError, VafNoError

var forceExit = false
var lastError: VafError = VafNoError

proc handler() {.noconv.} =
    # this will cause every thread to close its file stream, vaf will close on it's own afterwards
    forceExit = true
setControlCHook(handler)

let p = newParser("vaf"):
  option("-u", "--url", help="Target URL. Replace fuzz area with FUZZ")
  option("-w", "--wordlist", help="The path to the wordlist.")
  option("-m", "--method", default=some("GET"), help="Request method. Supported: POST, GET")
  option("-H", "--header", help="Specify HTTP headers; can be used multiple times. Example: -H 'header1: val1' -H 'header1: val1'", multiple=true)
  option("-pf", "--prefix", default=some(""), help="The prefixes to append to the word")
  option("-sf", "--suffix", default=some(""), help="The suffixes to append to the word")
  option("-t", "--threads", default=some("5"), help="Number of threads")
  option("-sc", "--status", default=some("200, 204, 302, 301, 307, 401"), help="The status to filter; to 'any' to print on any status")
  option("-g", "--grep", default=some(""), help="Only log if the response body contains the string")
  option("-ng", "--notgrep", default=some(""), help="Only log if the response body does no contain a string")
  option("-pd", "--postdata", default=some("{}"), help="Specify POST data; used only if '-m post' is set")
  option("-x", "--proxy", default=some(""), help="Specify a proxy")
  option("-ca", "--cafile", default=some(""), help="Specify a CA root certificate; useful if you are using Burp/ZAP proxy")
  option("-o", "--output", default=some(""), help="Output the results in a file")
  option("-mr", "--maxredirects", default=some("0"), help="How many redirects should vaf follow; 0 means none")
  flag("-v", "--version", help="Print version information")
  flag("-pif", "--printifreflexive", help="Print only if the fuzzed word is reflected in the page")
  flag("-i", "--ignoressl", help="Do not verify SSL certificates; useful if you are using Burp/ZAP proxy")
  flag("-ue", "--urlencode", help="URL encode the fuzzed words")
  flag("-pu", "--printurl", help="Print the requested URL")
  flag("-ph", "--printheaders", help="Print response headers")
  flag("-dbg", "--debug", help="Prints debug information")

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
    let displayPostData: string = postData
    let displayUrl: string = url
    let prefixes = parsedArgs.prefix.split(",")
    let suffixes = parsedArgs.suffix.split(",")

    var options: seq[string] = @[]
    if parsedArgs.printifreflexive:
        options.add("Print if reflexive")
    if parsedArgs.urlencode:
        options.add("URL encode")

    # Basic checkins of arguments

    if url == "" or wordlist == "":
        log("error", "Please specify an URL to fuzz using '-u' and a wordlist using '-w'.")
        quit(QuitFailure)

    if not os.fileExists(wordlist):
        log("error", "File " & wordlist & " does not exist.")
        quit(QuitFailure)
    
    if not (("FUZZ" in url) or (parsedArgs.header.anyIt("FUZZ" in it))) and (requestMethod == "GET"):
        log("error", "Please specify a fuzz area in the url or headers, example: `-u https://example.org/` or `-H 'User-Agent: '`")
        quit(QuitFailure)

    if not (("FUZZ" in postData) or ("FUZZ" in url) or ((parsedArgs.header.anyIt("FUZZ" in it)))) and (requestMethod == "POST"):
        log("error", "Please specify a fuzz area in the post data or the url, example: '{\"username\": \"\"}' or 'https://example.org/'")
        quit(QuitFailure)

    echo ""

    # Print a summary of arguments

    log("header", "Argument summary")
    log("option", "Target", displayUrl)
    log("option", "Method", requestMethod)
    log("option", "Status", printOnStatus.join(", "))
    log("option", "Threads", parsedArgs.threads)
    if requestMethod == "POST":
        log("option", "Post Data", displayPostData)
    if not ( grep == "" ): 
        log("option", "Grep", grep)
    if not ( parsedArgs.notgrep == "" ): 
        log("option", "Not Grep", parsedArgs.notgrep)
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
    
    # This object is sent to threads

    let fuzzData: FuzzArguments = FuzzArguments(
        url: url,
        grep: grep,
        notgrep: parsedArgs.notgrep,
        printOnStatus: printOnStatus,
        postData: postData,
        requestMethod: requestMethod,
        urlencode: parsedArgs.urlencode,
        wordlistFile: wordlist,
        suffixes: suffixes,
        prefixes: prefixes,
        printurl: parsedArgs.printurl,
        maxredirects: parseInt(parsedArgs.maxredirects),
        threadcount: parseInt(parsedArgs.threads),
        output: parsedArgs.output,
        printifreflexive: parsedArgs.printifreflexive,
        debug: parsedArgs.debug,
        printheaders: parsedArgs.printheaders,
        proxy: parsedArgs.proxy,
        caFile: parsedArgs.cafile,
        ignoreSSL: parsedArgs.ignoressl,
        headers: parsedArgs.header
    )

    # Splits the wordlist in multiple to be used by the threads

    let (wordlistFiles, wordlistsSize) = prepareWordlist(fuzzData)
    
    echo ""
    
    # Channel in which the fuzz results will be communicated

    var chan: Channel[(FuzzResult, int)]
    chan.open()

    #[ We doing this so if the user supplied 10 words and 100 threads, only 10 threads will be created ]#
    let threadCount = len(wordlistFiles) 
    var threads = newSeq[Thread[tuple[threadId: int, threadArguments: ThreadArguments]]](threadCount)

    proc fuzz(word: string, client: HttpClient, args: FuzzArguments, threadId: int): void =
        let urlToRequest: string = args.url.replace("FUZZ", word)

        var headers: seq[tuple[key: string, val: string]] = @[]

        for header in args.headers:
            let s = header.split(":") 
            let k = s[0].strip.replace("FUZZ", word)
            let v = s[1..(len(s)-1)].join(":").strip.replace("FUZZ", word)
            
            headers.add((key: k, val: v))

        let resp: FuzzResponse = makeRequest(urlToRequest, args.requestMethod, args.postData.replace("FUZZ", word), newHttpHeaders(headers), client)
        let fuzzResult: FuzzResult = FuzzResult(
            word: word, 
            statusCode: resp.statusCode, 
            urlencoded: args.urlencode, 
            url: urlToRequest, 
            printUrl: args.printurl, 
            response: resp
        )
    
        chan.send((fuzzResult, threadId))

    proc threadFunction(data: tuple[threadId: int, threadArguments: ThreadArguments]) {.thread.} =
        let threadData: ThreadArguments = data.threadArguments
        var verifyMode = CVerifyPeer
        if threadData.fuzzData.ignoreSSL:
            verifyMode= CVerifyNone
        let sslContext: SslContext = newContext(caFile=threadData.fuzzData.caFile, verifyMode=verifyMode)
        var proxy: Proxy = nil
        if threadData.fuzzData.proxy != "":
            proxy = newProxy(threadData.fuzzData.proxy)
        let client: HttpClient = newHttpClient(sslContext=sslContext, proxy=proxy, maxRedirects=threadData.fuzzData.maxredirects)
        
        if threadData.fuzzData.debug:
            echo "ThreadID: " & $data.threadId & " | got to deal with the " & threadData.wordlistFile & " wordlist"

        let strm = newFileStream(threadData.wordlistFile, fmRead)
        var line = ""
        if not isNil(strm):
            while strm.readLine(line) and not forceExit:
                if threadData.fuzzData.debug:
                    log("debug", "ThreadID: " & $data.threadId & " | " & " fuzzing w/ " & line)
                try:
                    fuzz(line, client, threadData.fuzzData, data.threadId)
                except SslError:
                    let msg = getCurrentExceptionMsg()
                    if "certificate verify failed" in msg:
                        lastError = VafSSLVerificationError
                    else:
                        log("error", fmt"Uncaught SSL Error: {msg}")
                    forceExit = true

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
    
    while true and not forceExit:
        
        let tried = chan.tryRecv()
        if tried.dataAvailable:

            let (fuzzResult, threadId) = tried.msg
            let resp = fuzzResult.response

            # Apply the status code filter
            let s: bool = len(filter(printOnStatus, proc(x: string): bool = x in resp.statusCode)) > 0
            
            if  (s or 
                (printOnStatus[0] == "any")) and 
                (((fuzzResult.word in resp.content) or decodeUrl(fuzzResult.word) in resp.content) or 
                not parsedArgs.printifreflexive) and 
                (parsedArgs.grep in resp.content) and 
                ( not (parsedArgs.notgrep in resp.content) or parsedArgs.notgrep == ""):
                printResponse(fuzzResult, fuzzData, threadId)
            
                # Save the result to the file
                if not (parsedArgs.output == ""):
                    saveTofile(fuzzResult, parsedArgs.output)

            inc fuzzProgress
            fuzzPercentage = (fuzzProgress / wordlistsSize * 100).int

            if fuzzProgress == wordlistsSize:
                break

        # Cool progress bar 😎
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

    if forceExit:
        log("warn", "Force exit, shutting down all threads...")
        if not ( lastError == VafNoError ):
            if lastError == VafSSLVerificationError:
                log("error", "SSL Verification failed, you might need to specify a CA root certificate file using '-ca' or ignore SSL verification with '-i'")

    # Wait for all threads to finish
    joinThreads(threads)
    
    echo ""
    log("info", &"Finished in {formatDuration(now() - timeStarted)}")

    # Delete the wordlists that were created
    cleanWordlists(wordlistFiles)
except ShortCircuit as e:
  if e.flag == "argparse_help":
    echo p.help
    echo """Examples:
  Fuzz URL path, show only responses which returned 200 OK 
    vaf -u https://example.org/ -w path/to/wordlist.txt -sc OK
  Fuzz 'User-Agent' header, show only responses which returned 200 OK 
    vaf -u https://example.org/ -w path/to/wordlist.txt -sc OK -H "User-Agent: "
  Fuzz POST data, show only responses which returned 200 OK
    vaf -u https://example.org/ -w path/to/wordlist.txt -sc OK -m POST -H "Content-Type: application/json" -pd '{"username": ""}' 
Report bugs:
  https://github.com/d4rckh/vaf/issues/new/choose
  """
    quit(0)