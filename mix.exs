defmodule Liquex.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :liquex,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "liquex",
      source_url: "https://github.com/markglenn/liquex",
      homepage_url: "https://github.com/markglenn/liquex",
      docs: [main: "Liquex", extras: ["README.md"]],
      aliases: aliases(),
      package: [
        maintainers: ["markglenn@gmail.com"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/markglenn/liquex"}
      ]
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
      {:nimble_parsec, "~> 0.5.3"},
      {:timex, "~> 3.6.1"},
      {:html_entities, "~> 0.5.1"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:inch_ex, "~> 0.1", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict", "dialyzer --halt-exit-status"]
    ]
  end

  defp description do
    """
    Liquid template parser for Elixir.  It tries to be 100% compatible with the Liquid
    gem for Ruby.
    """
  end
end
