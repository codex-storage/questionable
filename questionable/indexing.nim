import std/macros

when (NimMajor, NimMinor) < (1, 4):
  type IndexDefect = IndexError

macro `.?`*(expression: typed, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: expression.?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])
      try:
        `expression`[`index`].some
      except KeyError:
        T.none
      except IndexDefect:
        T.none
