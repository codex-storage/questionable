import std/macros
import ./private/scope

macro `.?`*(expression: typed, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: expression.?[index]
  let index = brackets[0]
  quote do:
    scope:
      type T = typeof(`expression`[`index`])
      try:
        `expression`[`index`].some
      except KeyError:
        T.none
