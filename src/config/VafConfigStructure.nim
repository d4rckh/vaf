import VafWordlist

type
  VafConfigStructure* = object
    DefaultWordlist*: int
    Wordlists*: seq[VafWordlist]