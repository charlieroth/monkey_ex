# `MonkeyEx`

The Monkey programming language from the book [Writing An Interpreter In Go](https://interpreterbook.com) by Thorsten Ball. Implemented in Elixir 🧙‍♂️.

## Supported Functionality

- `let`, `if`, `return` statements
- functions
- integers, booleans, string (wip)

## How To Use

Start an `iex` shell and use the `MonkeyEx.run/1` function

```bash
$ iex -S mix
iex(2)> MonkeyEx.run("""
...(2)> let x = 5;
...(2)> let y = 10;
...(2)> x + y;
...(2)> """)
15
iex(3)> MonkeyEx.run("""
...(3)> let add = fn(x, y) {
...(3)> return x + y;
...(3)> }
...(3)> add(5, 10);
...(3)> """)
15
```
