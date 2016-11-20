defmodule Vutuv.AddressController do
  use Vutuv.Web, :controller
  alias Vutuv.Address

  plug Vutuv.Plug.AuthUser when action in [:new, :create, :edit, :update]

  def index(conn, _params) do
    user = 
      conn.assigns[:user]
      |> Repo.preload(:addresses)
    render(conn, "index.html", user: user, addresses: user.addresses)
  end

  def new(conn, _params) do
    changeset = Address.changeset(%Address{}, %{})
    loc = Vutuv.UserHelpers.locale(conn, conn.assigns[:user])
    loc = if Vutuv.Plug.Locale.locale_supported?(loc), do: loc, else: "generic"
    render conn, "new.html", country: loc, changeset: changeset
  end

  def create(conn, %{"address" => address_params}) do
    changeset =
      conn.assigns[:user]
      |> build_assoc(:addresses)
      |> Address.changeset(address_params)
    case Repo.insert(changeset) do
      {:ok, _address} ->
        conn
        |> put_flash(:info, gettext("Address created successfully."))
        |> redirect(to: user_address_path(conn, :index, conn.assigns[:user]))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, country: changeset.changes.country)
    end
  end

  def create(conn, %{"country_select" => country_param}) do
    changeset = Address.changeset(%Address{}, country_param)
    render conn, "new.html", changeset: changeset, country: country_param["country"]
  end

  def show(conn, %{"id" => id}) do
    address = Repo.get!(Address, id)
    render(conn, "show.html", address: address)
  end

  def edit(conn, %{"id" => id}) do
    loc = Vutuv.UserHelpers.locale(conn, conn.assigns[:user])
    loc = if Vutuv.Plug.Locale.locale_supported?(loc), do: loc, else: "generic"
    address = Repo.get!(Address, id)
    changeset = Address.changeset(address)
    render(conn, "edit.html", address: address, changeset: changeset, country: loc)
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    address = Repo.get!(assoc(conn.assigns[:user], :addresses), id)
    changeset = Address.changeset(address, address_params)

    case Repo.update(changeset) do
      {:ok, address} ->
        conn
        |> put_flash(:info, gettext("Address updated successfully."))
        |> redirect(to: user_address_path(conn, :show, conn.assigns[:user], address))
      {:error, changeset} ->
        render(conn, "edit.html", address: address, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    address = Repo.get!(Address, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(address)

    conn
    |> put_flash(:info, gettext("Address deleted successfully."))
    |> redirect(to: user_address_path(conn, :index, conn.assigns[:user]))
  end
end
