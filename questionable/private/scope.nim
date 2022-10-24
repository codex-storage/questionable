proc neverhappens {.inline, noreturn.} =
  discard

template scope*(body): untyped =
  ## Can be used instead of `block` to introduce a new scoped block of code,
  ## without influencing any `break` statements in the code.
  ##
  ## See also: https://github.com/nim-lang/RFCs/issues/451
  if true:
    body
  else:
    # call {.noreturn.} proc here to ensure that the compiler uses `body` for
    # the result value of the if-statement
    neverhappens()
