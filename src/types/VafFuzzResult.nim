type
  VafFuzzResult* = object
    word*: string
    statusCode*: string
    urlencoded*: bool
    url*: string
    printUrl*: bool
    responseLength*: int
    responseTime*: int64