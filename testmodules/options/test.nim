import std/unittest
import std/sequtils
import pkg/questionable

suite "optionals":

  test "?Type is shorthand for Option[Type]":
    check (?int is Option[int])
    check (?string is Option[string])
    check (?seq[bool] is Option[seq[bool]])

  test ".? can be used for chaining optionals":
    let a: ?seq[int] = @[41, 42].some
    let b: ?seq[int] = seq[int].none
    check a.?len == 2.some
    check b.?len == int.none
    check a.?len.?uint8 == 2'u8.some
    check b.?len.?uint8 == uint8.none

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
      check false

    if b =? 42.some:
      check b == 42
    else:
      check false

    while a =? 42.some:
      check a == 42
      break

    while a =? int.none:
      check false
      break

  test "=? can appear multiple times in conditional expression":
    if a =? 42.some and b =? "foo".some:
      check a == 42
      check b == "foo"
    else:
      check false

  test "=? works with variable hiding":
    let a = 42.some
    if a =? a:
      check a == 42

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

    # Operators

    numbers = @[1, 2, 3].some
    x = 39.some

    let indexed = numbers[0]
    check indexed == 1.some
    let sum = x + 3
    check sum == 42.some
