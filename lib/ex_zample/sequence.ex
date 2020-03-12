defmodule ExZample.Sequence do
  @moduledoc false
  use Agent

  alias ExZample.SequenceRegistry

  def start_link(%{sequence_name: sequence_name, sequence_fun: sequence_fun} = params) do
    initial_index = Map.get(params, :initial_index, 1)
    Agent.start_link(fn -> {sequence_fun, initial_index} end, name: via(sequence_name))
  end

  def next(sequence_name), do: Agent.get_and_update(via(sequence_name), &get_and_update/1)

  defp get_and_update({sequence_fun, index}),
    do: {sequence_fun.(index), {sequence_fun, index + 1}}

  defp via(name), do: {:via, Registry, {SequenceRegistry, name}}
end
