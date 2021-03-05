import std/unittest
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
