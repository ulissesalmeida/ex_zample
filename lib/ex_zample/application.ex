defmodule ExZample.Application do
  @moduledoc false

  use Application

  alias ExZample.Manifest

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor,
       name: ExZample.SequenceSupervisor,
       strategy: :one_for_one,
       max_restarts: 100,
       max_seconds: 1},
      {Registry,
       name: ExZample.SequenceRegistry, keys: :unique, partitions: System.schedulers_online()}
    ]

    opts = [strategy: :one_for_all, name: ExZample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def start_phase(:load_manifest, _start_type, [manifest_dir]) do
    files =
      manifest_dir
      |> Path.join("/ex_zample/manifest/**/*.ex_zample_manifest.elixir")
      |> Path.wildcard()

    Enum.each(files, fn file ->
      manifest = Manifest.ensure_loaded(file)

      Enum.each(manifest.aliases, fn {scope, aliases} ->
        ExZample.config_aliases(scope, aliases)
      end)

      manifest.sequences
      |> Enum.flat_map(&extract_sequence_fun/1)
      |> Enum.each(fn {scope, name, sequence_fun} ->
        ExZample.create_sequence(scope, name, sequence_fun)
      end)

      Manifest.persist!(file, manifest)
    end)

    :ok
  end

  defp extract_sequence_fun({scope, aliases}) do
    Enum.map(aliases, fn {name, {mod, fun, args}} ->
      sequence_fun = apply(mod, fun, args)
      {scope, name, sequence_fun}
    end)
  end
end
