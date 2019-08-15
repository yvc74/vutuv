defmodule VutuvWeb.EmailAddressController do
  use VutuvWeb, :controller

  import VutuvWeb.Authorize

  alias Vutuv.{Accounts, Accounts.EmailAddress}
  alias VutuvWeb.{Auth.Otp, Email}

  @dialyzer {:nowarn_function, new: 3}

  def action(conn, _), do: auth_action_slug(conn, __MODULE__)

  def index(conn, _params, user) do
    email_addresses = Accounts.list_email_addresses(user)
    render(conn, "index.html", email_addresses: email_addresses)
  end

  def new(conn, _params, _user) do
    changeset = Accounts.change_email_address(%EmailAddress{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"email_address" => email_address_params}, user) do
    case Accounts.create_email_address(user, email_address_params) do
      {:ok, email_address} ->
        verify_email(conn, %{"email" => email_address.value}, "verify this email address", true)

      {:error, %Ecto.Changeset{} = changeset} ->
        if Accounts.duplicate_email_error?(changeset) do
          verify_email(
            conn,
            %{"email" => email_address_params["value"]},
            "verify this email address",
            false
          )
        else
          render(conn, "new.html", changeset: changeset)
        end
    end
  end

  def verify_email(conn, %{"email" => email}, msg, unique_email) do
    code =
      if unique_email do
        user_credential = Accounts.get_user_credential(%{"email" => email})
        Otp.create(user_credential.otp_secret)
      end

    Email.verify_request(email, code)
    message = "We have sent you an email. Please follow the instructions to #{msg}."

    conn
    |> put_flash(:info, message)
    |> redirect(to: Routes.verification_path(conn, :new, email: email))
  end

  def show(conn, %{"id" => id}, user) do
    email_address = Accounts.get_email_address!(user, %{"id" => id})
    render(conn, "show.html", email_address: email_address)
  end

  def edit(conn, %{"id" => id}, user) do
    email_address = Accounts.get_email_address!(user, %{"id" => id})
    changeset = Accounts.change_email_address(email_address)
    render(conn, "edit.html", email_address: email_address, changeset: changeset)
  end

  def update(conn, %{"id" => id, "email_address" => email_address_params}, user) do
    email_address = Accounts.get_email_address!(user, %{"id" => id})

    case Accounts.update_email_address(email_address, email_address_params) do
      {:ok, email_address} ->
        conn
        |> put_flash(:info, "Email address updated successfully.")
        |> redirect(to: Routes.user_email_address_path(conn, :show, user, email_address))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", email_address: email_address, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    email_address = Accounts.get_email_address!(user, %{"id" => id})
    {:ok, _email_address} = Accounts.delete_email_address(email_address)

    conn
    |> put_flash(:info, "Email address deleted successfully.")
    |> redirect(to: Routes.user_email_address_path(conn, :index, user))
  end
end
