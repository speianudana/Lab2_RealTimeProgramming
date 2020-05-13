defmodule EventsourceEx.Message do
  defstruct event: "message", data: nil
  @type t :: struct
end
