defmodule ProgramTest do
  use ExUnit.Case

  alias Mirlang.Token

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
            token: %Token{type: :let, literal: "let"},
            name: %Identifier{
              token: %Token{type: :ident, literal: "myVar"},
              value: "myVar"
            },
            value: %Identifier{
              token: %Token{type: :ident, literal: "anotherVar"},
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
