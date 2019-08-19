defmodule Vutuv.Accounts do
  @moduledoc """
  Accounts context.
  """

  alias Vutuv.{Accounts.UserCredential, Devices.EmailAddress, Repo, Sessions, UserProfiles}

  @type changeset_error :: {:error, Ecto.Changeset.t()}

  @doc """
  Gets user credentials. Raises error if no user_credential found.
  """
  @spec get_user_credential!(map) :: UserCredential.t() | no_return
  def get_user_credential!(%{"email" => email}) do
    %EmailAddress{user_id: user_id} = Repo.get_by!(EmailAddress, %{value: email})
    get_user_credential!(%{"user_id" => user_id})
  end

  def get_user_credential!(%{"user_id" => user_id}) do
    Repo.get_by!(UserCredential, %{user_id: user_id})
  end

  @doc """
  Gets user credentials. Returns nil if no user_credential found.
  """
  @spec get_user_credential(map) :: UserCredential.t() | nil
  def get_user_credential(%{"email" => email}) do
    with %EmailAddress{user_id: user_id} <- Repo.get_by(EmailAddress, %{value: email}),
         do: get_user_credential(%{"user_id" => user_id})
  end

  def get_user_credential(%{"user_id" => user_id}) do
    Repo.get_by(UserCredential, %{user_id: user_id})
  end

  @doc """
  Confirms a user's account, setting the user_credential's confirmed value.
  """
  @spec confirm_user(UserCredential.t()) :: {:ok, UserCredential.t()} | changeset_error
  def confirm_user(user_credential) do
    user_credential |> UserCredential.confirm_changeset(true) |> Repo.update()
  end

  @doc """
  Updates a user's password.
  """
  @spec update_password(UserCredential.t(), map) :: {:ok, UserCredential.t()} | changeset_error
  def update_password(%UserCredential{user_id: user_id} = user_credential, attrs) do
    Sessions.delete_user_sessions(UserProfiles.get_user!(%{"id" => user_id}))

    user_credential
    |> UserCredential.update_password_changeset(attrs)
    |> Repo.update()
  end
end
