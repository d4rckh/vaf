import std/[times]
import strformat
import net
import httpclient
import strutils

import ../types/VafFuzzResponse
import VafLogger

proc makeRequest*(url: string, requestType: string, postData: string, headers: HttpHeaders, client: HttpClient): FuzzResponse = 
    var response: Response = nil
    let time1 = now()
    if requestType == "GET":
        response = client.request(url, httpMethod = HttpGet, headers = headers)
    if requestType == "POST":
        response = client.request(url, httpMethod = HttpPost, headers = headers, body = postData)
    let time2 = now()
    return FuzzResponse(
        content: response.body, 
        statusCode: response.status, 
        responseLength: len(response.body), 
        url: url, 
        responseTime: (time2 - time1).inMilliseconds,
        headers: response.headers
    )
    