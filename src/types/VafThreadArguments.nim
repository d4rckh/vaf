import VafFuzzArguments

type
    ThreadArguments* = object
        fuzzData*: FuzzArguments
        wordlistFile*: string