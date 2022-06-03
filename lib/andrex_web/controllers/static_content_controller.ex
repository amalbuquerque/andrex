defmodule AndrexWeb.StaticContentController do
  alias Andrex.StaticContent
  require Logger
  use AndrexWeb, :controller

  action_fallback AndrexWeb.FallbackController

  def static_content(conn, _params) do
    file_path = conn.path_params["path"]
                |> Path.join()

    Logger.debug("Serving '#{file_path}' static content...")

    with {:ok, contents, content_type} <- StaticContent.get_static_content(file_path) do
      conn
      |> put_resp_content_type(content_type)
      |> send_resp(200, contents)
    end
  end
end
