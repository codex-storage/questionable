import std/unittest
import std/sequtils
import std/tables
import std/sugar
import pkg/questionable

suite "optionals":

  test "?Type is shorthand for Option[Type]":
    check (?int is Option[int])
    check (?string is Option[string])
    check (?seq[bool] is Option[seq[bool]])

  test "! gets value or raises Defect":
    check !42.some == 42
    expect Defect: discard !int.none

  test ".? can be used for chaining optionals":
    let a: ?seq[int] = @[41, 42].some
    let b: ?seq[int] = seq[int].none
    check a.?len == 2.some
    check b.?len == int.none
    check a.?len.?uint8 == 2'u8.some
    check b.?len.?uint8 == uint8.none
    check a.?len() == 2.some
    check b.?len() == int.none
    check a.?distribute(2).?len() == 2.some
    check b.?distribute(2).?len() == int.none

  test ".? chain can be followed by . calls and operators":
    let a = @[41, 42].some
    check a.?len.unsafeGet == 2
    check a.?len.unsafeGet.uint8.uint64 == 2'u64
    check a.?len.unsafeGet() == 2
    check a.?len.unsafeGet().uint8.uint64 == 2'u64
    check a.?deduplicate()[0].?uint8.?uint64 == 41'u64.some
    check a.?len + 1 == 3.some
    check a.?deduplicate()[0] + 1 == 42.some
    check a.?deduplicate.map(x => x) == @[41, 42].some

  test ".? chains work in generic code":
    proc test[T](a: ?T) =
      check a.?len == 2.some
      check a.?len.?uint8 == 2'u8.some
      check a.?len() == 2.some
      check a.?distribute(2).?len() == 2.some
      check a.?len.unsafeGet == 2
      check a.?len.unsafeGet.uint8.uint64 == 2'u64
      check a.?len.unsafeGet() == 2
      check a.?len.unsafeGet().uint8.uint64 == 2'u64
      check a.?deduplicate()[0].?uint8.?uint64 == 41'u64.some
      check a.?len + 1 == 3.some
      check a.?deduplicate()[0] + 1 == 42.some
      check a.?deduplicate.map(x => x) == @[41, 42].some

    test @[41, 42].some

  test "[] can be used for indexing optionals":
    let a: ?seq[int] = @[1, 2, 3].some
    let b: ?seq[int] = seq[int].none
    check a[1] == 2.some
    check a[^1] == 3.some
    check a[0..1] == @[1, 2].some
    check b[1] == int.none

  test "|? can be used to specify a fallback value":
    check 42.some |? 40 == 42
    check int.none |? 42 == 42

  test "=? can be used for optional binding":
    if a =? int.none:
      fail

    if b =? 42.some:
      check b == 42
    else:
      fail

    while a =? 42.some:
      check a == 42
      break

    while a =? int.none:
      fail
      break

  test "=? can appear multiple times in conditional expression":
    if a =? 42.some and b =? "foo".some:
      check a == 42
      check b == "foo"
    else:
      fail

  test "=? works with variable hiding":
    let a = 42.some
    if a =? a:
      check a == 42

  test "=? works with var":
    if var a =? 1.some and var b =? 2.some:
      check a == 1
      inc a
      check a == b
      inc b
      check b == 3
    else:
      fail

    if var a =? int.none:
      fail

  test "=? works with .?":
    if a =? 42.some.?uint8:
      check a == 42.uint8
    else:
      fail

  test "=? works in generic code":
    proc toString[T](option: ?T): string =
      if value =? option:
        $value
      else:
        "none"

    check 42.some.toString == "42"
    check int.none.toString == "none"

  test "=? works in generic code with variable hiding":
    let value {.used.} = "ignored"

    proc toString[T](option: ?T): string =
      if value =? option:
        $value
      else:
        "none"

    check 42.some.toString == "42"
    check int.none.toString == "none"

  test "=? works with closures":
    var called = false
    let closure = some(proc () = called = true)

    if a =? none(proc ()):
      a()

    check not called

    if a =? closure:
      a()

    check called

  test "=? works with types that do not have a default value":
    type NoDefault {.requiresInit.} = distinct int
    proc `==`(a,b: NoDefault): bool {.borrow.}

    if a =? some NoDefault(42):
      check a == NoDefault(42)
    else:
      fail()

    if var a =? some NoDefault(42):
      check a == NoDefault(42)
    else:
      fail()

  test "=? works with reference types":
    var x = new int
    x[] = 42
    if a =? x:
      check a[] == 42
    else:
      fail

    x = nil
    if a =? x:
      fail

    var p = proc = discard
    if a =? p:
      a()
    else:
      fail

    p = nil
    if a =? p:
      fail

    when (NimMajor, NimMinor) >= (1, 1) and (NimMajor, NimMinor) != (2, 0):
      var it = iterator: int = yield 2
      if a =? it:
        for x in a:
          check x == 2
      else:
        fail

      it = nil
      if a =? it:
        fail

  test "=? rejects non-reference types":
    check `not` compiles do:
      if a =? 0:
        discard
    check `not` compiles do:
      if var a =? 0:
        discard
    check `not` compiles do:
      if (a,) =? (0,):
        discard

  test "=? works with custom optional types":
    type MyOption = distinct int
    proc isSome(x: MyOption): bool = x.int >= 0
    proc unsafeGet(x: MyOption): int = x.int
    template toOption(x: MyOption): MyOption = x

    if a =? MyOption 42:
      check a == 42
    else:
      fail

    if a =? MyOption -1:
      fail

  test "=? binds and unpacks tuples":
    if (a, b) =? (some ("test", 1)):
      check a == "test"
      check b == 1
    else:
      fail()

    if (a, b) =? none (string, int):
      discard a
      discard b
      fail()

  test "=? binds and unpacks tuples with named fields":
    if (a, b) =? (some (desc: "test", id: 1)):
      check a == "test"
      check b == 1
    else:
      fail()

  test "=? binds and unpacks tuples returned from proc":
    proc returnsTuple(): ?tuple[name: string, id: int] = some ("test", 1)

    if (a, b) =? returnsTuple():
      check a == "test"
      check b == 1
    else:
      fail()

  test "=? binds and unpacks tuples returned from proc with unnamed fields":
    proc returnsTuple(): ?(string, int,) = some ("test", 1,)

    if (a, b,) =? returnsTuple():
      check a == "test"
      check b == 1
    else:
      fail()

  test "=? binds and unpacks tuples with _":
    if (_, b) =? some ("test", 1):
      check b == 1
    else:
      fail()

  test "=? binds and unpacks tuples with named fields":
    if (a, b) =? some (desc: "test", id: 1):
      check a == "test"
      check b == 1
    else:
      fail()

  test "=? binds variable to tuples with named fields":
    if t =? some (desc: "test", id: 1):
      check t.desc == "test"
      check t.id == 1
    else:
      fail()

  test "=? binds to tuple types":
    type MyTuple = tuple
      desc: string
      id: int

    let mt: MyTuple = ("test", 1)

    if t =? (some mt):
      check t.desc == "test"
      check t.id == 1
    else:
      fail()

    if (a, b) =? (some mt):
      check a == "test"
      check b == 1
    else:
      fail()

  test "=? for tuples does not leak symbols into caller's scope":
    const evaluated = ""
    type T = string
    if (a,) =? some (0,):
      check a == 0
      check option is proc
      check evaluated is string
      check T is string

  test "without statement can be used for early returns":
    proc test1 =
      without a =? 42.some:
        fail
        return
      check a == 42

    proc test2 =
      without a =? int.none:
        return
      fail

    test1()
    test2()

  test "without statement evaluates optional expression only once":
    var count = 0
    without a =? (inc count; 42.some):
      discard
    check count == 1

  test ".?[] can be used for indexing tables without raising KeyError":
    let table = @{"a": 1, "b": 2}.toTable
    check table.?["a"] == 1.some
    check table.?["c"] == int.none

  test ".?[] can be used for indexing strings without raising IndexDefect":
    let str = "a"
    check str.?[0] == 'a'.some
    check str.?[1] == char.none
    check str.?[-1] == char.none

  test ".?[] can be used for indexing sequences without raising IndexDefect":
    let sequence = @[1]
    check sequence.?[0] == 1.some
    check sequence.?[1] == int.none
    check sequence.?[-1] == int.none

  test ".?[] can be used for indexing openArrays without raising IndexDefect":
    proc checkOpenArray(oa: openArray[int]): void =
      check oa.?[0] == 1.some
      check oa.?[1] == int.none
      check oa.?[-1] == int.none

    checkOpenArray(@[1])

  test ".?[] evaluates openArray expression only once":
    var count = 0
    discard (inc count; @[1].toOpenArray(0, 0)).?[0]
    check count == 1

  test ".?[] can be followed by calls, operators and indexing":
    let table = @{"a": @[41, 42]}.toTable
    check table.?["a"].isSome
    check table.?["a"].isSome()
    check table.?["a"][0] == 41.some
    check table.?["a"].?len.unsafeGet == 2
    check table.?["a"].?len.unsafeGet.uint8.uint64 == 2'u64
    check table.?["a"].?len.unsafeGet() == 2
    check table.?["a"].?len.unsafeGet().uint8.uint64 == 2'u64
    check table.?["a"].?deduplicate()[0].?uint8.?uint64 == 41'u64.some
    check table.?["a"].?len + 1 == 3.some
    check table.?["a"].?deduplicate()[0] + 1 == 42.some
    check table.?["a"].?deduplicate.map(x => x) == @[41, 42].some

  test "=? works with .?[]":
    let table = @{"a": 42}.toTable
    if a =? table.?["a"]:
      check a == 42
    else:
      fail

  test "unary operator `-` works for options":
    check -(-42.some) == 42.some
    check -(int.none) == int.none

  test "other unary operators work for options":
    check +(42.some) == 42.some
    check @([1, 2].some) == (@[1, 2]).some

  test "binary operator `+` works for options":
    check 40.some + 2.some == 42.some
    check 40.some + 2 == 42.some
    check int.none + 2 == int.none
    check 40.some + int.none == int.none
    check int.none + int.none == int.none

  test "other binary operators work for options":
    check 21.some * 2 == 42.some
    check 84'f.some / 2'f == 42'f.some
    check 84.some div 2 == 42.some
    check 85.some mod 43 == 42.some
    check 0b00110011.some shl 1 == 0b01100110.some
    check 0b00110011.some shr 1 == 0b00011001.some
    check 44.some - 2 == 42.some
    check "f".some & "oo" == "foo".some
    check 40.some <= 42 == true.some
    check 40.some < 42 == true.some
    check 40.some >= 42 == false.some
    check 40.some > 42 == false.some

  test ".? avoids wrapping option in option":
    let a = 41.some

    proc b(x: int): ?int =
      some x + 1

    check a.?b == 42.some

  test "lifted operators avoid wrapping option in option":
    let a = 40.some
    let b = 2.some

    func `&`(x, y: int): ?int =
      some x + y

    check (a & b) == 42.some

  test ".?[] avoids wrapping option in option":
    let a = @[41, 42].some

    check a.?[1] == 42.some

  test ".? chain evaluates optional expression only once":
    var count = 0
    discard (inc count; @[41, 42].some).?len
    check count == 1

  test "=? evaluates optional expression only once":
    var count = 0
    if a =? (inc count; 42.some):
      let b {.used.} = a
    check count == 1

    count = 0
    if var a =? (inc count; 42.some):
      let b {.used.} = a
    check count == 1

  test "|? evaluates optional expression only once":
    var count = 0
    discard (inc count; 42.some) |? 43
    check count == 1

  test ".?[] evaluates optional expression only once":
    # indexing on optional sequence:
    block:
      var count = 0
      discard (inc count; @[41, 42].some).?[0]
      check count == 1
    # indexing on normal sequence:
    block:
      var count = 0
      discard (inc count; @[41, 42]).?[0]
      check count == 1

  test "lifted unary operators evaluate optional expression only once":
    var count = 0
    discard -(inc count; 42.some)
    check count == 1

  test "lifted binary operators evaluate optional expressions only once":
    # lifted operator on two options:
    block:
      var count1, count2 = 0
      discard (inc count1; 40.some) + (inc count2; 2.some)
      check count1 == 1
      check count2 == 1
    # lifted operator on option and value:
    block:
      var count1, count2 = 0
      discard (inc count1; 40.some) + (inc count2; 2)
      check count1 == 1
      check count2 == 1

  test "examples from readme work":

    var x: ?int

    x = 42.some
    x = int.none

    # Option binding

    x = 42.some

    if y =? x:
      check y == 42
    else:
      fail

    x = int.none

    if y =? x:
      fail
    else:
      check not compiles(y)

    # without statement

    proc someProc(option: ?int) =
      without value =? option:
        check option.isNone
        return

      check value == 42

    someProc(int.none)
    someProc(42.some)

    # Option chaining

    var numbers: ?seq[int]
    var amount: ?int

    numbers = @[1, 2, 3].some
    amount = numbers.?len
    check amount == 3.some

    numbers = seq[int].none
    amount = numbers.?len
    check amount == int.none

    numbers = @[1, 1, 2, 2, 2].some
    amount = numbers.?deduplicate.?len
    check amount == 2.some

    # Fallback values

    x = int.none

    let z = x |? 3
    check z == 3

    # Obtaining value with !

    x = 42.some
    let dare = !x
    check dare == 42

    x = int.none
    expect Defect:
      let crash {.used.} = !x

    # Operators

    numbers = @[1, 2, 3].some
    x = 39.some

    let indexed = numbers[0]
    check indexed == 1.some
    let sum = x + 3
    check sum == 42.some
