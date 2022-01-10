import std/macros
import ./resultsbase
import ./options
import ./binding
import ./chaining
import ./indexing
import ./operators
import ./without
import ./withoutresult

include ./errorban

export resultsbase except ok, err, isOk, isErr, get
export binding
export chaining
export indexing
export without
export withoutresult

type ResultFailure* = object of CatchableError

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  ## Use `?!` make a Result type. These Result types either hold a value or
  ## an error. For example the type `?!int` is short for
  ## `Result[int, ref CatchableError]`.

  Result[T, ref CatchableError]

template `!`*[T](value: ?!T): T =
  ## Returns the value of a Result when you're absolutely sure that it
  ## contains value. Using `!` on a Result without a value raises a Defect.

  value.get

proc success*[T](value: T): ?!T =
  ## Creates a successfull Result containing the value.
  ##
  ok(?!T, value)

proc success*: ?!void =
  ## Creates a successfull Result without a value.

  ok(?!void)

proc failure*(T: type, error: ref CatchableError): ?!T =
  ## Creates a failed Result containing the error.

  err(?!T, error)

proc failure*(T: type, message: string): ?!T =
  ## Creates a failed Result containing a `ResultFailure` with the specified
  ## error message.

  T.failure newException(ResultFailure, message)

template failure*(error: ref CatchableError): auto =
  ## Creates a failed Result containing the error.

  err error

template failure*(message: string): auto =
  ## Creates a failed Result containing the error.

  failure newException(ResultFailure, message)

proc isSuccess*[T](value: ?!T): bool =
  ## Returns true when the Result contains a value.

  value.isOk

proc isFailure*[T](value: ?!T): bool =
  ## Returns true when the Result contains an error.

  value.isErr

template `->?`*[T,U](value: ?!T, expression: ?!U): ?!U =
  if value.isFailure:
    U.failure(value.error)
  else:
    expression

template `->?`*[T,U](value: ?!T, expression: U): ?!U =
  value ->? expression.success

template `->?`*[T,U,V](values: (?!T, ?!U), expression: ?!V): ?!V =
  if values[0].isFailure:
    V.failure(values[0].error)
  elif values[1].isFailure:
    V.failure(values[1].error)
  else:
    expression

template `->?`*[T,U,V](values: (?!T, ?!U), expression: V): ?!V =
  values ->? expression.success

template `|?`*[T,E](value: Result[T,E], fallback: T): T =
  ## Use the `|?` operator to supply a fallback value when a Result does not
  ## hold a value.

  value.valueOr(fallback)

proc option*[T,E](value: Result[T,E]): ?T =
  ## Converts a Result into an Option.

  if value.isOk:
    try: # workaround for erroneous exception tracking when T is a closure
      value.unsafeGet.some
    except Exception as exception:
      raise newException(Defect, exception.msg, exception)
  else:
    T.none

Result.liftUnary(`-`)
Result.liftUnary(`+`)
Result.liftUnary(`@`)
Result.liftBinary(`[]`)
Result.liftBinary(`*`)
Result.liftBinary(`/`)
Result.liftBinary(`div`)
Result.liftBinary(`mod`)
Result.liftBinary(`shl`)
Result.liftBinary(`shr`)
Result.liftBinary(`+`)
Result.liftBinary(`-`)
Result.liftBinary(`&`)
Result.liftBinary(`<=`)
Result.liftBinary(`<`)
Result.liftBinary(`>=`)
Result.liftBinary(`>`)
