# `MonkeyEx`

The Monkey programming language from the book [Writing An Interpreter In Go](https://interpreterbook.com) by Thorsten Ball; implemented in Elixir 🧙‍♂️.

## How To Use

Start a `iex` shell

```bash
$ iex -S mix
iex(1)> MonkeyEx.run(""" 
...(1)> # Write program here 
...(1)> """)
```

Use `MonkeyEx.run/1` to execute a program that is supported. See examples below for an idea of what is available.

## Examples

### `let` Statements

```bash
iex(1)> MonkeyEx.run("""
...(1)> let x = 5;
...(1)> let y = 10;
...(1)> x + y;
...(1)> """)
15
```

### String Concatenation

```bash
iex(2)> MonkeyEx.run("""
...(2)> let firstName = "Charlie";
...(2)> let lastName = "Roth";
...(2)> let fullName = firstName + \" \" + lastName;
...(2)> fullName;
...(2)> """)
"Charlie Roth"
```

### Functions

```bash
iex(1)> MonkeyEx.run("""
...(1)> let add = fn(x, y) {
...(1)>   return x + y;
...(1)> }
...(1)> add(5, 10);
...(1)> """)
15
```

### `if/else` Statements

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

### Infix Expressions

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

### Prefix Operators

```bash
iex(2)> MonkeyEx.run("""
...(2)> let negTen = -10;
...(2)> let one = 1;
...(2)> one + negTen;
...(2)> """)
-9
```
