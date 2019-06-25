defmodule NervesTier do
  use GenServer
  require Logger

  defp token!() do
    File.read!(Path.join(@zt_home, "/authtoken.secret"))
  end

  def info() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/status?auth=#{token!()}") |> Poison.decode!()
  end

  def networks() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/networks?auth=#{token!()}") |> Poison.decode!()
  end

  def network(id) do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/network/#{id}?auth=#{token!()}") |> Poison.decode!()
  end

  def peers() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/networks?auth=#{token!()}") |> Poison.decode!()
  end

end

defmodule NervesTier.PortServer do
  use GenServer
  require Logger

  # Callbacks
  @zt_home "/root/.zt/"
  @zt_port 9993

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts ++ [name: __MODULE__])
  end

  @impl true
  def init(args \\ []) do

    GenServer.cast(self(), :start)
    {:ok, %{port: nil}}
  end

  @impl true
  def handle_cast(:start, state) do

    zt_bin =  "#{:code.priv_dir(:nerves_tier)}/usr/sbin/zerotier-one"
    Logger.info("Starting ZerotierOne")
    port = Port.open({:spawn_executable, zt_bin}, [:binary, args: [@zt_home]])

    {:noreply, %{ state | port: port} }
  end

  def handle_call(:status, state) do
    {:replay, Port.info(state.port), state}
  end

end

defmodule NervesTier.Application do
  use Application

  @moduledoc """
  Documentation for NervesTier.
  """

  def start(_type, _args) do
    children = [
      NervesTier.PortServer,
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
