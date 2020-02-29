defmodule ExZample.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_zample,
      version: "0.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "ExZample",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.20", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
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
      extras: ["README.md"]
    ]
  end
end
