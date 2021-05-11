import VafWordlist

type
  VafConfigStructure* = object
    VersionNumber*: string
    DefaultWordlist*: int
    Wordlists*: seq[VafWordlist]