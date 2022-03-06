import httpclient
import VafResponse

var client = newHttpClient()

proc makeRequest*(url: string, requestType: string, postData: string): VafResponse = 
    if requestType == "GET":
        var response: Response = client.request(url, httpMethod = HttpGet)
        return VafResponse(content: response.body, statusCode: response.status, responseLength: len(response.body))
    if requestType == "POST":
        var customHeaders = newHttpHeaders({
            "Content-Type": "application/json"
        })
        var response: Response = client.request(url, httpMethod = HttpPost, headers = customHeaders, body = postData)
        return VafResponse(content: response.body, statusCode: response.status, responseLength: len(response.body), url: url)
