defmodule ExZample.Manifest do
  @moduledoc false

  @manifest_vsn 1

  def write!(file, factories) do
    write_manifest!(file, %{
      aliases: Enum.reduce(factories, %{}, &build_factory_manifest/2)
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

  defp write_manifest!(file, manifest) do
    binary = :erlang.term_to_binary({@manifest_vsn, manifest})

    file |> Path.dirname() |> File.mkdir_p!()
    File.write!(file, binary)
  end

  defp put_alias(aliases, name, module, scope) do
    Map.update(aliases, name, module, fn existent_factory ->
      raise ArgumentError, """
      The alias #{inspect(name)} already exists!
      It is registered with the factory #{inspect(existent_factory)} and
      can't be replaced with the new #{inspect(module)} in #{inspect(scope)} scope.
      Rename the alias or add it in a different scope.
      """
    end)
  end

  def ensure_loaded(file) do
    manifest = read(file)

    %{
      aliases: Enum.reduce(manifest.aliases, %{}, &ensure_scope_exists/2)
    }
  end

  defp read(file) when is_binary(file) do
    with {:ok, binary} <- File.read(file),
         {@manifest_vsn, manifest} when is_map(manifest) <- :erlang.binary_to_term(binary) do
      manifest
    else
      _ ->
        %{aliases: %{}}
    end
  end

  defp ensure_scope_exists({scope, aliases}, loaded_scopes) do
    loaded_aliases = Enum.reduce(aliases, %{}, &ensure_factory_exists/2)

    if loaded_aliases == %{} do
      loaded_scopes
    else
      Map.put(loaded_scopes, scope, loaded_aliases)
    end
  end

  defp ensure_factory_exists({name, factory_module}, existent_factories) do
    if Code.ensure_loaded?(factory_module) do
      Map.put(existent_factories, name, factory_module)
    else
      existent_factories
    end
  end

  def persist!(file, manifest) do
    if manifest.aliases == %{} do
      File.rm(file)
    else
      write_manifest!(file, manifest)
    end
  end
end
