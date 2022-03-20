import VafFuzzArguments

type
    VafThreadArguments* = object
        fuzzData*: VafFuzzArguments
        words*: seq[string]