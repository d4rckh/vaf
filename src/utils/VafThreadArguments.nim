import VafFuzzArguments

type
    VafThreadArguments* = object
        threadId*: int
        startIndex*: int
        endIndex*: int
        fuzzData*: VafFuzzArguments