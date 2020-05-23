defmodule ExZample.Manifest do
  @moduledoc false

  @manifest_vsn 1

  @doc false
  def write!(file, factories, sequences) do
    write_manifest!(file, %{
      aliases: Enum.reduce(factories, %{}, &build_factory_manifest/2),
      sequences: Enum.reduce(sequences, %{}, &build_sequence_manifest/2)
    })
  end

  defp build_factory_manifest({scope, name, factory_module}, manifest) do
    Map.update(
      manifest,
      scope,
      %{name => factory_module},
      &put_alias(&1, name, factory_module, scope)
    )
  end

  defp build_sequence_manifest({scope, name, sequence_fun}, manifest) do
    Map.update(
      manifest,
      scope,
      %{name => sequence_fun},
      &put_alias(&1, name, sequence_fun, scope)
    )
  end

  defp write_manifest!(file, manifest) do
    binary = :erlang.term_to_binary({@manifest_vsn, manifest})

    file |> Path.dirname() |> File.mkdir_p!()
    File.write!(file, binary)
  end

  defp put_alias(aliases, name, new_item, scope) do
    Map.update(aliases, name, new_item, fn existent_item ->
      raise ArgumentError, """
      The alias #{inspect(name)} already exists!
      It is registered with #{inspect(existent_item)} and
      can't be replaced with the new #{inspect(new_item)} in #{inspect(scope)} scope.
      Rename the alias or add it in a different scope.
      """
    end)
  end

  @doc false
  def ensure_loaded(file) do
    manifest = read(file)

    %{
      aliases: Enum.reduce(manifest.aliases, %{}, &ensure_definitions_exists/2),
      sequences: Enum.reduce(manifest.sequences, %{}, &ensure_definitions_exists/2)
    }
  end

  defp read(file) when is_binary(file) do
    with {:ok, binary} <- File.read(file),
         {@manifest_vsn, manifest} when is_map(manifest) <- :erlang.binary_to_term(binary) do
      manifest
    else
      _ ->
        %{aliases: %{}, sequences: %{}}
    end
  end

  defp ensure_definitions_exists({scope, aliases}, loaded_scopes) do
    loaded_aliases = Enum.reduce(aliases, %{}, &ensure_item_exists/2)

    if loaded_aliases == %{} do
      loaded_scopes
    else
      Map.put(loaded_scopes, scope, loaded_aliases)
    end
  end

  # NOTE: for sequences
  defp ensure_item_exists({name, {module, fun, args} = sequence}, existent_sequences) do
    if Code.ensure_loaded?(module) && function_exported?(module, fun, length(args)) do
      Map.put(existent_sequences, name, sequence)
    else
      existent_sequences
    end
  end

  # NOTE: for factories
  defp ensure_item_exists({name, factory_module}, existent_factories) do
    if Code.ensure_loaded?(factory_module) do
      Map.put(existent_factories, name, factory_module)
    else
      existent_factories
    end
  end

  @doc false
  def persist!(file, manifest) do
    if manifest.aliases == %{} do
      File.rm(file)
    else
      write_manifest!(file, manifest)
    end
  end
end
