import std/times

# stolen from https://nim-by-example.github.io/for_iterators/
iterator countTo*(n: int): int =
  var i = 0
  while i <= n:
    yield i
    inc i

proc formatDuration*(duration: Duration): string =
    let dt = initTime(0, 0).utc + duration
    return dt.format("mm:ss:fff")