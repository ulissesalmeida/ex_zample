defmodule ExZample.Application do
  @moduledoc false

  use Application

  alias ExZample.Manifest

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: ExZample.SequenceSupervisor, strategy: :one_for_one},
      {Registry,
       name: ExZample.SequenceRegistry, keys: :unique, partitions: System.schedulers_online()},
      {Task, &load_manifest/0}
    ]

    opts = [strategy: :one_for_all, name: ExZample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def load_manifest do
    files =
      Mix.Project.manifest_path()
      |> Path.join("**/*.ex_zample_manifest.elixir")
      |> Path.wildcard()

    Enum.each(files, fn file ->
      manifest = Manifest.ensure_loaded(file)

      Enum.each(manifest.aliases, fn {scope, aliases} ->
        ExZample.config_aliases(scope, aliases)
      end)

      Manifest.persist!(file, manifest)
    end)
  end
end
