defmodule NervesTier.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_tier,
      version: "0.2.1",
      elixir: "~> 1.6",
      compilers: [:elixir_make] ++ Mix.compilers,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {NervesTier.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Simple wrapper api & port server tro run ZeroTierOne on Nerves devices.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "test", "Makefile"],
      maintainers: ["Jaremy Creechley"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elcritch/nerves_tier"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:httpoison, "~> 1.5", optional: true},
      {:poison, "~> 3.1", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
