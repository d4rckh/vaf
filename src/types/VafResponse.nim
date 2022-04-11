type
  FuzzResponse* = object
    content*: string
    statusCode*: string
    responseLength*: int
    url*: string
    responseTime*: int64