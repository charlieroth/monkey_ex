# `MonkeyEx`

The Monkey programming language from the book [Writing An Interpreter In Go](https://interpreterbook.com) by Thorsten Ball. Implemented in Elixir 🧙‍♂️.

## Supported Functionality

- `let`, `if`, `return` statements
- functions
- integers, booleans, string (wip)

## How To Use

Start an `iex` shell and use the `MonkeyEx.run/1` function

## Examples

### `let` statements

```bash
iex(1)> MonkeyEx.run("""
...(1)> let x = 5;
...(1)> let y = 10;
...(1)> x + y;
...(1)> """)
15
```

### functions

```bash
iex(1)> MonkeyEx.run("""
...(1)> let add = fn(x, y) {
...(1)> return x + y;
...(1)> }
...(1)> add(5, 10);
...(1)> """)
15
```

### `if/else` statement

```bash
iex(1)> MonkeyEx.run("""
...(1)> let age = 21;
...(1)> 
...(1)> let canDrive = fn(ageOfPerson) {
...(1)>   if (ageOfPerson > 18) {
...(1)>     return true;
...(1)>   } else {
...(1)>     return false;
...(1)>   }
...(1)> }
...(1)> 
...(1)> canDrive(age);
...(1)> """)
true
```

### infix expressions

```bash
iex(2)> MonkeyEx.run("""
...(2)> let age = 18;
...(2)> let ageInThreeYears = fn(age) { return age + 3; }
...(2)> let canDrive = fn(age) {
...(2)>   if (age > 18) {
...(2)>     return true;
...(2)>   } else {
...(2)>     return false;
...(2)>   }
...(2)> }
...(2)> canDrive(ageInThreeYears(18));
...(2)> """)
true
```
