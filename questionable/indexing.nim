import std/macros

macro `.?`*(expression: typed, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: expression.?[index]
  let index = brackets[0]
  quote do:
    type T = typeof(`expression`[`index`])
    try:
      `expression`[`index`].some
    except KeyError:
      T.none
