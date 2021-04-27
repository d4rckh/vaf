import httpclient
import VafResponse

var client = newHttpClient()

proc makeRequest*(url: string): VafResponse = 
    var response: Response = client.request(url, httpMethod = HttpGet)
    return VafResponse(content: response.body, statusCode: response.status, responseLength: len(response.body))
