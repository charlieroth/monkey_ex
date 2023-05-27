defmodule Mirlang.Token do
  @type t ::
          {:illegal, String.t()}
          | :eof
          | {:ident, String.t()}
          | {:int, String.t()}
          | :assign
          | :plus
          | :minus
          | :asterisk
          | :slash
          | :bang
          | :equal_equal
          | :not_equal
          | :greater_than
          | :less_than
          | :comma
          | :semicolon
          | :lparen
          | :rparen
          | :lbrace
          | :rbrace
          | :fn
          | :let
          | true
          | false
          | :if
          | :else
          | :return
end
