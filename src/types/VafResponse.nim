type
  VafResponse* = object
    content*: string
    statusCode*: string
    responseLength*: int
    url*: string
    responseTime*: int64