import VafFuzzArguments

type
    VafThreadArguments* = object
        fuzzData*: VafFuzzArguments
        wordlistFile*: string