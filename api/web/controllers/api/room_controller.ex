defmodule Sling.RoomController do
  use Sling.Web, :controller

  alias Sling.Room

plug Guardian.Plug.EnsureAuthenticated, [handler: Sling.SessionController] when action in [:rooms]

  def index(conn, _params) do
    rooms = Repo.all(Room)
    render(conn, "index.json", rooms: rooms)
  end

  def create(conn, params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Room.changeset(%Room{}, params)

    case Repo.insert(changeset) do
      {:ok, room} ->
        assoc_changeset = Sling.UserRoom.changeset(
          %Sling.UserRoom{},
          %{user_id: current_user.id, room_id: room.id}
        )
        Repo.insert(assoc_changeset)

        conn
        |> put_status(:created)
        |> render("show.json", room: room)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Sling.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def join(conn, %{"id" => room_id}) do
    current_user = Guardian.Plug.current_resource(conn)
    room = Repo.get(Room, room_id)

    changeset = Sling.UserRoom.changeset(
      %Sling.UserRoom{},
      %{room_id: room.id, user_id: current_user.id}
    )

    case Repo.insert(changeset) do
      {:ok, _user_room} ->
        conn
        |> put_status(:created)
        |> render("show.json", %{room: room})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Sling.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def rooms(conn, _params) do
    current_user = Guardian.Plug.current_resource(conn)
    rooms = Repo.all(assoc(current_user, :rooms))
    render(conn, Sling.RoomView, "index.json", %{rooms: rooms})
  end

end