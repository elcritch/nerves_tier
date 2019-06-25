defmodule NervesTier do
  use GenServer

  # Callbacks
  @zt_home "/root/.zt/"
  @zt_port 9993


  @impl true
  def init(args \\ []) do

    GenServer.cast(self(), :start)
    {:ok, %{port: nil}}
  end

  @impl true
  def handle_cast(:start, state) do

    zt_bin =  "#{:code.priv_dir(:nerves_tier)}/usr/sbin/zerotier-one"
    port = Port.open({:spawn_executable, path}, [:binary, args: [@zt_home]])

    {:noreply, %{ state | port: port} }
  end

  defp token!() do
    File.read!(Path.join(@zt_home, "/authtoken.secret"))
  end

  def info() do
    HTTPoison.get!("127.0.0.1:#{@zt_port}/status?auth=#{token!()}")
  end
end

defmodule NervesTier.Application do
  use Application

  @moduledoc """
  Documentation for NervesTier.
  """

  def start(_type, _args) do
    children = [
      NervesTier,
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
