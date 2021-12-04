Questionable 🤔
==============

[Option][1] and [Result][2] are two powerful abstractions that can be used
instead of raising errors. They can be a bit unwieldy though. This library is an
attempt at making their use a bit more elegant.

Installation
------------

Use the [Nimble][3] package manager to add `questionable` to an existing
project. Add the following to its .nimble file:

```nim
requires "questionable >= 0.10.1 & < 0.11.0"
```

If you want to make use of Result types, then you also have to add either the
[result][2] package, or the [stew][4] package:

```nim
requires "result" # either this
requires "stew"   # or this
```

Options
-------

You can use `?` to make a type optional. For example, the type `?int` is just
short for [`Option[int]`][1].

```nim
import questionable

var x: ?int
```

Assigning values is done using the `some` and `none` procs from the standard library:

```nim
x = 42.some   # Option x now holds the value 42
x = int.none  # Option x no longer holds a value
```
### Option binding

The `=?` operator lets you bind the value inside an Option to a new variable. It
can be used inside of a conditional expression, for instance in an `if`
statement:

```nim
x = 42.some

if y =? x:
  # y equals 42 here
else:
  # this is never reached

x = int.none

if y =? x:
  # this is never reached
else:
  # this is reached, and y is not defined
```

The `without` statement can be used to place guards that ensure that an Option
contains a value:

```nim
proc someProc(option: ?int) =
  without value =? option:
    # option did not contain a value
    return

  # use value
```

### Option chaining

To safely access fields and call procs, you can use the `.?` operator:

> Note: in versions 0.3.x and 0.4.x, the operator was `?.` instead of `.?`

```nim
var numbers: ?seq[int]
var amount: ?int

numbers = @[1, 2, 3].some
amount = numbers.?len
# amount now holds the integer 3

numbers = seq[int].none
amount = numbers.?len
# amount now equals int.none
```

Invocations of the `.?` operator can be chained:
```nim
import sequtils

numbers = @[1, 1, 2, 2, 2].some
amount = numbers.?deduplicate.?len
# amount now holds the integer 2
```

### Fallback values

Use the `|?` operator to supply a fallback value when the Option does not hold
a value:

```nim
x = int.none

let z = x |? 3
# z equals 3
```

### Obtaining value with !

The `!` operator returns the value of an Option when you're absolutely sure that
it contains a value.

```nim
x = 42.some
let dare = !x     # dare equals 42

x = int.none
let crash = !x    # raises a Defect
```

### Operators

The operators `[]`, `-`, `+`, `@`, `*`, `/`, `div`, `mod`, `shl`, `shr`, `&`,
`<=`, `<`, `>=`, `>` are all lifted, so they can be used directly on Options:

```nim
numbers = @[1, 2, 3].some
x = 39.some

let indexed = numbers[0]  # equals 1.some
let sum = x + 3           # equals 42.some
```

Results
-------

Support for `Result` is considered experimental. If you want to use them you
have to explicitly import the `questionable/results` module:

```nim
import questionable/results
```

You can use `?!` make a Result type. These Result types either hold a value or
an error. For example the type `?!int` is short for `Result[int, ref
CatchableError]`.

```nim
proc example: ?!int =
  # either return an integer or an error
```

Results can be made using the `success` and `failure` procs:

```nim
proc works: ?!seq[int] =
  # always returns a Result holding a sequence
  success @[1, 1, 2, 2, 2]

proc fails: ?!seq[int] =
  # always returns a Result holding an error
  failure "something went wrong"
```

### Binding, chaining, fallbacks and operators

Binding with the `=?` operator, chaining with the `.?` operator, fallbacks with
the `|?` operator, and all the other operators that work with Options also work
for Results:
```nim
import sequtils

# binding:
if x =? works():
  # use x

# chaining:
let amount = works().?deduplicate.?len

# fallback values:
let value = fails() |? @[]

# lifted operators:
let sum = works()[3] + 40
```

### Catching errors

When you want to use Results, but need to call a proc that may raise an
error, you can use `catch`:

```nim
import strutils

let x = parseInt("42").catch  # equals 42.success
let y = parseInt("XX").catch  # equals int.failure(..)
```

### Conversion to Option

Any Result can be converted to an Option:

```nim
let converted = works().option  # equals @[1, 1, 2, 2, 2].some
```

[1]: https://nim-lang.org/docs/options.html
[2]: https://github.com/arnetheduck/nim-result
[3]: https://github.com/nim-lang/nimble
[4]: https://github.com/status-im/nim-stew
