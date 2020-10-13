defmodule ExZample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_zample,
      version: "0.10.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "ExZample",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_file: {:no_warn, "plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExZample.Application, []},
      start_phases: [load_manifest: [Mix.Project.build_path()]],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.20", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:postgrex, "~> 0.15.0", only: [:dev, :test]},
      {:mox, "~> 1.0", only: [:test]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ] ++ ecto_deps()
  end

  defp ecto_deps do
    # NOTE: The most recent version of Ecto doesn't support Elixir 1.6
    if Version.match?(System.version(), ">= 1.7.0") do
      [
        {:ecto, "~> 3.0", optional: true},
        {:ecto_sql, "~> 3.0", only: [:dev, :test]}
      ]
    else
      [
        {:ecto, "~> 3.2.0", optional: true},
        {:ecto_sql, "~> 3.2.0", only: [:dev, :test]}
      ]
    end
  end

  def description do
    "A scalable error-friendly factories for your Elixir apps"
  end

  def package do
    [
      name: "ex_zample",
      maintainers: ["Ulisses Almeida"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ulissesalmeida/ex_zample"}
    ]
  end

  def docs do
    [
      source_url: "https://github.com/ulissesalmeida/ex_zample",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
