import std/[times]
import httpclient

import ../types/VafFuzzResponse

proc makeRequest*(url: string, requestType: string, postData: string, client: HttpClient): FuzzResponse = 
    var response: Response = nil
    let time1 = now()
    if requestType == "GET":
        response = client.request(url, httpMethod = HttpGet)
    if requestType == "POST":
        var customHeaders = newHttpHeaders({
            "Content-Type": "application/json"
        })
        response = client.request(url, httpMethod = HttpPost, headers = customHeaders, body = postData)
    let time2 = now()
    return FuzzResponse(
        content: response.body, 
        statusCode: response.status, 
        responseLength: len(response.body), 
        url: url, 
        responseTime: (time2 - time1).inMilliseconds,
        headers: response.headers
    )
    