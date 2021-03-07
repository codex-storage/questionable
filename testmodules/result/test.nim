import std/unittest
import std/strutils
import pkg/questionable/results

suite "result":

  let error = newException(CatchableError, "error")

  test "?!Type is shorthand for Result[Type, ref CatchableError]":
    check (?!int is Result[int, ref CatchableError])
    check (?!string is Result[string, ref CatchableError])
    check (?!seq[bool] is Result[seq[bool], ref CatchableError])

  test ".? can be used for chaining results":
    let a: ?!seq[int] = @[41, 42].success
    let b: ?!seq[int] = seq[int].failure error
    check a.?len == 2.success
    check b.?len == int.failure error
    check a.?len.?uint8 == 2'u8.success
    check b.?len.?uint8 == uint8.failure error

  test "[] can be used for indexing optionals":
    let a: ?!seq[int] = @[1, 2, 3].success
    let b: ?!seq[int] = seq[int].failure error
    check a[1] == 2.success
    check a[^1] == 3.success
    check a[0..1] == @[1, 2].success
    check b[1] == int.failure error

  test "|? can be used to specify a fallback value":
    check 42.success |? 40 == 42
    check int.failure(error) |? 42 == 42

  test "=? can be used for optional binding":
    if a =? int.failure(error):
      check false

    if b =? 42.success:
      check b == 42
    else:
      check false

    while a =? 42.success:
      check a == 42
      break

    while a =? int.failure(error):
      check false
      break

  test "=? can appear multiple times in conditional expression":
    if a =? 42.success and b =? "foo".success:
      check a == 42
      check b == "foo"
    else:
      check false

  test "=? works with variable hiding":
    let a = 42.success
    if a =? a:
      check a == 42

  test "catch can be used to convert exceptions to results":
    check parseInt("42").catch == 42.success
    check parseInt("foo").catch.error of ValueError

  test "unary operator `-` works for results":
    check -(-42.success) == 42.success
    check -(int.failure(error)) == int.failure(error)

  test "other unary operators work for results":
    check +(42.success) == 42.success
    check @([1, 2].success) == (@[1, 2]).success

  test "binary operator `+` works for results":
    check 40.success + 2.success == 42.success
    check 40.success + 2 == 42.success
    check int.failure(error) + 2 == int.failure(error)
    check 40.success + int.failure(error) == int.failure(error)
    check int.failure(error) + int.failure(error) == int.failure(error)

  test "other binary operators work for results":
    check (21.success * 2 == 42.success)
    check (84'f.success / 2'f == 42'f.success)
    check (84.success div 2 == 42.success)
    check (85.success mod 43 == 42.success)
    check (0b00110011.success shl 1 == 0b01100110.success)
    check (0b00110011.success shr 1 == 0b00011001.success)
    check (44.success - 2 == 42.success)
    check ("f".success & "oo" == "foo".success)
    check (40.success <= 42 == true.success)
    check (40.success < 42 == true.success)
    check (40.success >= 42 == false.success)
    check (40.success > 42 == false.success)
