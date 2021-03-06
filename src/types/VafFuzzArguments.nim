type
    FuzzArguments* = object
        url*: string
        grep*: string
        notgrep*: string
        printOnStatus*: seq[string]
        postData*: string
        requestMethod*: string
        proxy*: string
        caFile*: string
        wordlistFile*: string
        headers*: seq[string]
        prefixes*: seq[string]
        suffixes*: seq[string]
        threadcount*: int
        maxredirects*: int
        urlencode*: bool
        printurl*: bool
        output*: string
        printifreflexive*: bool
        debug*: bool
        printheaders*: bool        
        ignoreSSL*: bool