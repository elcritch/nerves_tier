defmodule NervesTier do
  require Logger

  @zt_home Application.get_env(:nerves_tier, :zt_home, "/root/.zt/")
  @zt_port Application.get_env(:nerves_tier, :zt_conf_port, 9993)
  @zt_networks Application.get_env(:nerves_tier, :zt_networks, [])

  defp token!() do
    File.read!(Path.join(@zt_home, "/authtoken.secret"))
  end

  def info() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/status?auth=#{token!()}").body |> Poison.decode!()
  end

  def networks() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/networks?auth=#{token!()}").body |> Poison.decode!()
  end

  def network(:defaults) do
    for nt <- @zt_networks, into: %{} do
      {nt, network(nt)}
    end
  end

  def network(id) do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/network/#{id}?auth=#{token!()}").body |> Poison.decode!()
  end

  def network_join(id, params \\ %{}) do
    HTTPoison.post!("127.0.0.1:#{@zt_port}/network/#{id}?auth=#{token!()}", params |> Poison.encode!()).body |> Poison.decode!()
  end

  def network_leave(id) do
    HTTPoison.delete!("127.0.0.1:#{@zt_port}/network/#{id}?auth=#{token!()}").body |> Poison.decode!()
  end

  def peers() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/networks?auth=#{token!()}").body |> Poison.decode!()
  end

end

defmodule NervesTier.PortServer do
  use GenServer
  require Logger

  # Callbacks
  @zt_home Application.get_env(:nerves_tier, :zt_home, "/root/.zt/")
  @reset_sleep_ms Application.get_env(:nerves_tier, :reset_sleep_ms, 5_000)
  @startup_delay Application.get_env(:nerves_tier, :startup_delay, 15_000)

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts ++ [name: __MODULE__])
  end

  @impl true
  def init(_args \\ []) do

    GenServer.cast(self(), :start)
    Process.flag(:trap_exit, true)
    {:ok, %{port: nil}}
  end

  @impl true
  def handle_info(:check, state) do
    with true <- is_port(state.port),
         true <- is_map(NervesTier.info())
    do
      GenServer.cast(self(), :join_defaults)
    else
      err ->
        Logger.error "zerotier port not alive: #{inspect err}"
        Process.sleep(@reset_sleep_ms)
        raise "zerotier error"
    end
    {:noreply, state }
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error "zerotier info: #{inspect msg}"
    {:noreply, state }
  end

  @impl true
  def handle_cast(:start, state) do
    Process.sleep( @startup_delay )
    Logger.info("Starting ZerotierOne")

     {_, 0} = System.cmd("modprobe", ["tun"])

    # run_zt =  "#{:code.priv_dir(:nerves_tier)}/run-zt.sh"
    zt_bin =  "#{:code.priv_dir(:nerves_tier)}/usr/sbin/zerotier-one"
    port = Port.open({:spawn_executable, zt_bin}, [:binary, args: [@zt_home]])
    # port = Port.open({:spawn_executable, run_zt}, [:binary, args: [zt_bin, @zt_home]])
    Process.send_after(self(), :check, 1_000, [])

    {:noreply, %{ state | port: port} }
  end

  def handle_cast(:join_defaults, state) do
    zt_networks = Application.get_env(:nerves_tier, :zt_networks, [])
    Logger.info("Joining ZeroTier networks: #{inspect zt_networks}")
    for network_id <- zt_networks do
      Logger.info("Joining ZeroTier network: #{inspect network_id}")
      status = NervesTier.network_join(network_id)
      _status_short = Map.take(status, ["status", "type", "name"])
      Logger.info("Default network status: #{inspect status}")
    end
    {:noreply, state }
  end

  def handle_call(:status, state) do
    {:reply, Port.info(state.port), state}
  end

  @impl true
  def handle_call(:port, _from, state) do
    {:reply, state.port, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.error "#{__MODULE__}.terminate/2 called with reason: #{inspect reason}"
    port_info = Port.info(state.port)
    Logger.error("#{__MODULE__}.termindate port: #{inspect port_info}")

    case port_info[:os_pid] do
      ospid when is_number(ospid) ->
        Logger.info "#{__MODULE__} terminate port, os process: #{inspect ospid}"
        System.cmd("kill", ["-KILL", "#{ospid}"], [])
      nil ->
        nil
    end
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
