import std/[times]
import strformat
import net
import httpclient
import strutils

import ../types/VafFuzzResponse
import VafLogger

proc makeRequest*(url: string, requestType: string, postData: string, client: HttpClient): FuzzResponse = 
    var response: Response = nil
    let time1 = now()
    try:
        if requestType == "GET":
            response = client.request(url, httpMethod = HttpGet)
        if requestType == "POST":
            var customHeaders = newHttpHeaders({
                "Content-Type": "application/json"
            })
            response = client.request(url, httpMethod = HttpPost, headers = customHeaders, body = postData)
    except SslError:
        echo ""
        let msg = getCurrentExceptionMsg()
        if "certificate verify failed" in msg:
            log("error", "SSL Verification failed, you might need to specify a CA root certificate file using '-ca' or ignore SSL verification with '-i'")
        else:
            log("error", fmt"SSL Error: {msg}")
        quit(1)
    let time2 = now()
    return FuzzResponse(
        content: response.body, 
        statusCode: response.status, 
        responseLength: len(response.body), 
        url: url, 
        responseTime: (time2 - time1).inMilliseconds,
        headers: response.headers
    )
    