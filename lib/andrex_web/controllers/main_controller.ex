defmodule AndrexWeb.MainController do
  require Logger
  use AndrexWeb, :controller
  alias Andrex.{Main, Blog}

  def page(conn, %{"article" => article}) do
    Logger.debug("Fetching #{conn.request_path}")

    case Main.get_page(article) do
      {:ok, %Blog.Entry{} = page} ->
        render(conn, "main.html", page: page.pandoc.html)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Page not found.")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
