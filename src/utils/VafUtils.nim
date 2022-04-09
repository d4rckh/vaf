# stolen from https://nim-by-example.github.io/for_iterators/
iterator countTo*(n: int): int =
  var i = 0
  while i <= n:
    yield i
    inc i
