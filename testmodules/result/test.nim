import std/unittest
import std/sequtils
import std/strutils
import std/sugar
import pkg/questionable
import pkg/questionable/results

suite "result":

  let error = newException(CatchableError, "error")

  test "?!Type is shorthand for Result[Type, ref CatchableError]":
    check (?!int is Result[int, ref CatchableError])
    check (?!string is Result[string, ref CatchableError])
    check (?!seq[bool] is Result[seq[bool], ref CatchableError])

  test "?. can be used for chaining results":
    let a: ?!seq[int] = @[41, 42].success
    let b: ?!seq[int] = seq[int].failure error
    check a?.len == 2.success
    check b?.len == int.failure error
    check a?.len?.uint8 == 2'u8.success
    check b?.len?.uint8 == uint8.failure error
    check a?.len() == 2.success
    check b?.len() == int.failure error
    check a?.distribute(2)?.len() == 2.success
    check b?.distribute(2)?.len() == int.failure error

  test "?. chain can be followed by . calls and operators":
    let a = @[41, 42].success
    check (a?.len.get == 2)
    check (a?.len.get.uint8.uint64 == 2'u64)
    check (a?.len.get() == 2)
    check (a?.len.get().uint8.uint64 == 2'u64)
    check (a?.deduplicate()[0]?.uint8?.uint64 == 41'u64.success)
    check (a?.len + 1 == 3.success)
    check (a?.deduplicate()[0] + 1 == 42.success)
    check (a?.deduplicate.map(x => x) == @[41, 42].success)

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
      fail

    if b =? 42.success:
      check b == 42
    else:
      fail

    while a =? 42.success:
      check a == 42
      break

    while a =? int.failure(error):
      fail
      break

  test "=? can appear multiple times in conditional expression":
    if a =? 42.success and b =? "foo".success:
      check a == 42
      check b == "foo"
    else:
      fail

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

  test "Result can be converted to Option":
    check 42.success.option == 42.some
    check int.failure(error).option == int.none

  test "examples from readme work":

    proc works: ?!seq[int] =
      @[1, 1, 2, 2, 2].success

    proc fails: ?!seq[int] =
      seq[int].failure newException(ValueError, "something went wrong")

    # binding:
    if x =? works():
      check x == @[1, 1, 2, 2, 2]
    else:
      fail

    # chaining:
    let amount = works()?.deduplicate?.len
    check (amount == 2.success)

    # fallback values:
    let value = fails() |? @[]
    check (value == newSeq[int](0))

    # lifted operators:
    let sum = works()[3] + 40
    check (sum == 42.success)

    # catch
    let x = parseInt("42").catch
    check (x == 42.success)
    let y = parseInt("XX").catch
    check y.isErr

    # Conversion to Option

    let converted = works().option
    check (converted == @[1, 1, 2, 2, 2].some)
