defmodule ExZample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: ExZample.SequenceSupervisor, strategy: :one_for_one},
      {Registry,
       name: ExZample.SequenceRegistry, keys: :unique, partitions: System.schedulers_online()}
    ]

    opts = [strategy: :one_for_all, name: ExZample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
