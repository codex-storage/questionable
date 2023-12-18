import std/options
import std/macros

# A stack of names of error variables. Keeps track of the error variables that
# are given to captureBindError().
var errorVariableNames {.global, compileTime.}: seq[string]

macro captureBindError*(error: var ref CatchableError, expression): auto =
  ## Ensures that an error is assigned to the error variable when a binding (=?)
  ## fails inside the expression.

  # name of the error variable as a string literal
  let errorVariableName = newLit($error)
  quote do:
    # add error variable to the top of the stack
    static: errorVariableNames.add(`errorVariableName`)
    # evaluate the expression
    let evaluated = `expression`
    # pop error variable from the stack
    static: discard errorVariableNames.pop()
    # return the evaluated result
    evaluated

func error[T](option: Option[T]): ref CatchableError =
  newException(ValueError, "Option is set to `none`")

macro bindFailed*(expression; _: type = void) =
  ## Called when a binding (=?) fails.
  ## Assigns an error to the error variable (specified in captureBindError())
  ## when appropriate.

  # This macro has a type parameter to ensure that the compiler does not
  # expand it before it expands invocations of captureBindError().

  # check that we have an error variable on the stack
  if errorVariableNames.len > 0:
    # create an identifier that references the current error variable
    let errorVariable = ident errorVariableNames[^1]
    return quote do:
      # check that the error variable is in scope
      when compiles(`errorVariable`):
        # assign bind error to error variable
        `errorVariable` = `expression`.error
