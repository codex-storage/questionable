import std/macros
import ./binding
import ./without

macro replaceInfix(expression, operator, replacement): untyped =
  ## Replaces an infix operator in an expression. The AST of the expression is
  ## traversed to find and replace all instances of the operator.

  proc replace(expression, operator, replacement: NimNode): NimNode =
    if expression.kind == nnkInfix and eqIdent(expression[0], operator):
      expression[0] = replacement
      expression[2] = replace(expression[2], operator, replacement)
    else:
      for i in 0..<expression.len:
        expression[i] = replace(expression[i], operator, replacement)
    expression

  replace(expression, operator, replacement)

template without*(condition, errorname, body) =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  var error: ref CatchableError

  # override =? operator such that it stores the error if there is one
  template `override=?`(name, expression): bool {.gensym, used.} =
    let optional = expression
    when optional is Result:
      if optional.isFailure:
        error = optional.error
    when optional is Option:
      if optional.isNone:
        error = newException(ValueError, "Option is set to `none`")
    name =? optional

  without replaceInfix(condition, `=?`, `override=?`):
    template errorname: ref CatchableError = error
    body
