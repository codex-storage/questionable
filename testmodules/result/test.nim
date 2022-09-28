import std/unittest
import std/options
import std/sequtils
import std/strutils
import std/sugar
import pkg/questionable/results

suite "result":

  let error = newException(CatchableError, "error")

  test "?!Type is shorthand for Result[Type, ref CatchableError]":
    check (?!int is Result[int, ref CatchableError])
    check (?!string is Result[string, ref CatchableError])
    check (?!seq[bool] is Result[seq[bool], ref CatchableError])

  test "! gets value or raises Defect":
    check !42.success == 42
    expect Defect: discard !int.failure error

  test ".? can be used for chaining results":
    let a: ?!seq[int] = @[41, 42].success
    let b: ?!seq[int] = seq[int].failure error
    check a.?len == 2.success
    check b.?len == int.failure error
    check a.?len.?uint8 == 2'u8.success
    check b.?len.?uint8 == uint8.failure error
    check a.?len() == 2.success
    check b.?len() == int.failure error
    check a.?distribute(2).?len() == 2.success
    check b.?distribute(2).?len() == int.failure error

  test ".? chain can be followed by . calls and operators":
    let a = @[41, 42].success
    check (a.?len.unsafeGet == 2)
    check (a.?len.unsafeGet.uint8.uint64 == 2'u64)
    check (a.?len.unsafeGet() == 2)
    check (a.?len.unsafeGet().uint8.uint64 == 2'u64)
    check (a.?deduplicate()[0].?uint8.?uint64 == 41'u64.success)
    check (a.?len + 1 == 3.success)
    check (a.?deduplicate()[0] + 1 == 42.success)
    check (a.?deduplicate.map(x => x) == @[41, 42].success)

  test ".? chains work in generic code":
    proc test[T](a: ?!T) =
      check (a.?len == 2.success)
      check (a.?len.?uint8 == 2'u8.success)
      check (a.?len() == 2.success)
      check (a.?distribute(2).?len() == 2.success)
      check (a.?len.unsafeGet == 2)
      check (a.?len.unsafeGet.uint8.uint64 == 2'u64)
      check (a.?len.unsafeGet() == 2)
      check (a.?len.unsafeGet().uint8.uint64 == 2'u64)
      check (a.?deduplicate()[0].?uint8.?uint64 == 41'u64.success)
      check (a.?len + 1 == 3.success)
      check (a.?deduplicate()[0] + 1 == 42.success)
      check (a.?deduplicate.map(x => x) == @[41, 42].success)

    test @[41, 42].success

  test "[] can be used for indexing results":
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

  test "=? works with var":
    if var a =? 1.success and var b =? 2.success:
      check a == 1
      inc a
      check a == b
      inc b
      check b == 3
    else:
      fail

    if var a =? int.failure(error):
      fail

  test "=? works with .?":
    if a =? 42.success.?uint8:
      check a == 42.uint8
    else:
      fail

  test "=? evaluates optional expression only once":
    var count = 0
    if a =? (inc count; 42.success):
      let b {.used.} = a
    check count == 1

    count = 0
    if var a =? (inc count; 42.success):
      let b {.used.} = a
    check count == 1

  test "=? works in generic code":
    proc toString[T](res: ?!T): string =
      if value =? res:
        $value
      else:
        "error"

    check 42.success.toString == "42"
    check int.failure(error).toString == "error"

  test "=? works in generic code with variable hiding":
    let value {.used.} = "ignored"

    proc toString[T](res: ?!T): string =
      if value =? res:
        $value
      else:
        "error"

    check 42.success.toString == "42"
    check int.failure(error).toString == "error"

  test "=? works with closures":
    var called = false
    let closure = success(proc () = called = true)

    if a =? failure(proc (), error):
      a()

    check not called

    if a =? closure:
      a()

    check called

  test "without statement works for results":
    proc test1 =
      without a =? 42.success:
        fail
        return
      check a == 42

    proc test2 =
      without a =? int.failure "error":
        return
      fail

    test1()
    test2()

  test "without statement can expose error":
    proc test =
      without a =? int.failure "some error", error:
        check error.msg == "some error"
        return
      fail

    test()

  test "without statement only exposes error variable inside block":
    proc test =
      without a =? 42.success, errorvar:
        fail
        discard errorvar # fixes warning about unused variable "errorvar"
        return
      check not compiles errorvar

    test()

  test "without statements with multiple bindings exposes first error":
    proc test1 =
      without (a =? int.failure "error 1") and
              (b =? int.failure "error 2"),
              error:
        check error.msg == "error 1"
        return
      fail

    proc test2 =
      without (a =? 42.success) and (b =? int.failure "error 2"), error:
        check error.msg == "error 2"
        return
      fail

    test1()
    test2()

  test "without statement with error evaluates result only once":
    proc test =
      var count = 0
      without a =? (inc count; int.failure "error"):
        check count == 1
        return
      fail

    test()

  test "without statement with error handles options as well":
    proc test1 =
      without a =? int.none and b =? int.failure "error", error:
        check error.msg == "Option is set to `none`"
        return
      fail

    proc test2 =
      without a =? 42.some and b =? int.failure "error", error:
        check error.msg == "error"
        return
      fail

    test1()
    test2()

  test "without statement with error can be used more than once":
    proc test =
      without a =? 42.success, error:
        discard error
        fail
      without b =? 42.success, error:
        discard error
        fail

    test()

  test "without statement with error works with deeply nested =? operators":
    proc test =
      let fail1 = int.failure "error 1"
      let fail2 = int.failure "error 2"
      without (block: a =? (if b =? fail1: b.success else: fail2)), error:
        check error.msg == "error 2"
        return
      fail

    test()

  test "without statement with error works in generic code":
    proc test(_: type) =
      without a =? int.failure "error", e:
        check e.msg == "error"
        return
      fail

    test(int)

  test "without statements with error can be nested":
    without a =? int.failure "error1", e1:
      without b =? int.failure "error2", e2:
        check e1.msg == "error1"
        check e2.msg == "error2"
      check e1.msg == "error1"

  test "without statement works in generic code using existing error name":
    let existingName {.used.} = "some variable"

    proc shouldCompile(_: type int): ?!int =
      without _ =? int.failure "error", existingName:
        check existingName.msg == "error"
        return success 42

    discard int.shouldCompile()

  test "without statements with error work in nested calls":
    proc bar(): ?!int =
      without _ =? int.failure "error", err:
        return failure err.msg

    proc foo() =
      without _ =? bar(), err:
        check err.msg == "error"
        return
      fail()

    foo()

  test "without statement with error works in nested generic calls":
    proc works(_: type int): ?!int =
      without _ =? int.failure "error1", error:
        check error.msg == "error1"
        return success 42

    proc fails(_: type int): ?!int =
      return failure "error2"

    proc foo =
      without a =? int.works() and b =? int.fails(), error:
        check error.msg == "error2"
        return
      fail()

    foo()

  test "catch can be used to convert exceptions to results":
    check parseInt("42").catch == 42.success
    check parseInt("foo").catch.error of ValueError

  test "success can be called without argument":
    check (success() is ?!void)

  test "failure can be called with string argument":
    let value = int.failure("some failure")
    check value.error of ResultFailure
    check value.error.msg == "some failure"

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

  test "Result error can be converted to Option":
    check (int.failure(error).errorOption == error.some)
    check (42.success.errorOption == (ref CatchableError).none)
    check (void.failure(error).errorOption == error.some)
    check (success().errorOption == (ref CatchableError).none)

  test "failure can be used without type parameter in procs":
    proc fails: ?!int =
      failure "some error"

    check fails().isFailure
    check fails().error.msg == "some error"

  test ".? avoids wrapping result in result":
    let a = 41.success

    proc b(x: int): ?!int =
      success x + 1

    check a.?b == 42.success

  test "lifted operators avoid wrapping result in result":
    let a = 40.success
    let b = 2.success

    func `&`(x, y: int): ?!int =
      success x + y

    check (a & b) == 42.success

  test ".? chain evaluates result only once":
    var count = 0
    discard (inc count; @[41, 42].success).?len
    check count == 1

  test "=? evaluates result only once":
    var count = 0
    if a =? (inc count; 42.success):
      let b {.used.} = a
    check count == 1

    count = 0
    if var a =? (inc count; 42.success):
      let b {.used.} = a
    check count == 1

  test "|? evaluates result only once":
    var count = 0
    discard (inc count; 42.success) |? 43
    check count == 1

  test ".?[] evaluates result only once":
    var count = 0
    discard (inc count; @[41, 42].success).?[0]
    check count == 1

  test "lifted unary operators evaluate result only once":
    var count = 0
    discard -(inc count; 42.success)
    check count == 1

  test "lifted binary operators evaluate results only once":
    # lifted operator on two options:
    block:
      var count1, count2 = 0
      discard (inc count1; 40.success) + (inc count2; 2.success)
      check count1 == 1
      check count2 == 1
    # lifted operator on option and value:
    block:
      var count1, count2 = 0
      discard (inc count1; 40.success) + (inc count2; 2)
      check count1 == 1
      check count2 == 1

  test "conversion to option evaluates result only once":
    var count = 0
    discard (inc count; 42.success).option
    check count == 1

  test "conversion to error evaluates result only once":
    var count = 0
    discard (inc count; int.failure(error)).errorOption
    check count == 1

  test "examples from readme work":

    proc works: ?!seq[int] =
      success @[1, 1, 2, 2, 2]

    proc fails: ?!seq[int] =
      failure "something went wrong"

    # binding:
    if x =? works():
      check x == @[1, 1, 2, 2, 2]
    else:
      fail

    # chaining:
    let amount = works().?deduplicate.?len
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
    check y.isFailure

    # Conversion to Option

    let converted = works().option
    check (converted == @[1, 1, 2, 2, 2].some)

    # Without statement
    proc someProc(r: ?!int) =
      without value =? r, error:
        check error.msg == "some error"
        return

      check value == 42

    someProc(42.success)
    someProc(int.failure "some error")


import pkg/questionable/resultsbase

suite "result compatibility":

  type R = Result[int, string]
  let good = R.ok 42
  let bad = R.err "error"

  test "|?, =? and .option work on other types of Result":
    check bad |? 43 == 43

    if value =? good:
      check value == 42
    else:
      fail

    check good.option == 42.some

  test "=? works on other type of Result after without statement with error":
    without a =? 42.success, error:
      discard error # fixes warning about unused variable "error"
      fail
    without b =? good:
      fail
