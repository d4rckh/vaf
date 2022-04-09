type
    VafFuzzArguments* = object
        url*: string
        grep*: string
        printOnStatus*: string
        postData*: string
        requestMethod*: string
        wordlistFile*: string
        prefixes*: seq[string]
        suffixes*: seq[string]
        urlencode*: bool
        printurl*: bool
        output*: string
        printifreflexive*: bool
        debug*: bool