defmodule ProgramTest do
  use ExUnit.Case

  alias MonkeyEx.Token

  alias MonkeyEx.Ast.{
    Program,
    LetStatement,
    Identifier
  }

  describe "print/1" do
    test "stringifies let statement" do
      program = %Program{
        statements: [
          %LetStatement{
            token: :let,
            name: %Identifier{
              token: {:ident, "myVar"},
              value: "myVar"
            },
            value: %Identifier{
              token: {:ident, "anotherVar"},
              value: "anotherVar"
            }
          }
        ]
      }

      stringified_program = program |> Program.string()
      assert stringified_program == "let myVar = anotherVar;"
    end
  end
end
