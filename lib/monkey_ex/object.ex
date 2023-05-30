defprotocol MonkeyEx.Object do
  @doc """
  Returns the type of the object as a string
  """
  @spec type(any()) :: String.t()
  def type(object)

  @doc """
  Outputs a stringified representation of the object
  """
  @spec inspect(any()) :: String.t()
  def inspect(object)
end
