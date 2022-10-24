import ../questionable/private/scope
import std/unittest

suite "Scope":

  test "introduces variable scope":
    var x = 1
    scope:
      var x: string
      x = "some string"
      check x == "some string"
    check x == 1

  test "returns value":
    let x = scope:
      3
    check x == 3
