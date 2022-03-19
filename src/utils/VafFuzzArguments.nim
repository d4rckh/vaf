type
    VafFuzzArguments* = object
        url*: string
        grep*: string
        printOnStatus*: string
        postData*: string
        requestMethod*: string
        urlencode*: bool
        printurl*: bool
        output*: string
        printifreflexive*: bool