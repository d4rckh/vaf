import VafFuzzResponse

type
  FuzzResult* = object
    word*: string
    statusCode*: string
    urlencoded*: bool
    url*: string
    printUrl*: bool
    response*: FuzzResponse