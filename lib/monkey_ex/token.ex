defmodule MonkeyEx.Token do
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

  def literal({:ident, identifier}), do: identifier
  def literal({:int, number}), do: number
  def literal(:assign), do: "="
  def literal(:plus), do: "+"
  def literal(:minus), do: "-"
  def literal(:asterisk), do: "*"
  def literal(:slash), do: "/"
  def literal(:bang), do: "!"
  def literal(:equal_equal), do: "=="
  def literal(:not_equal), do: "!="
  def literal(:greater_than), do: ">"
  def literal(:less_than), do: "<"
  def literal(:comma), do: ","
  def literal(:semicolon), do: ";"
  def literal(:lparen), do: "("
  def literal(:rparen), do: ")"
  def literal(:lbrace), do: "{"
  def literal(:rbrace), do: "}"
  def literal(:fn), do: "fn"
  def literal(:let), do: "let"
  def literal(true), do: "true"
  def literal(false), do: "false"
  def literal(:if), do: "if"
  def literal(:else), do: "else"
  def literal(:return), do: "return"
end
