defmodule Ipdth.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_admin_email, do: "admin#{System.unique_integer()}@ipdth.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def admin_user_fixture() do
    {:ok, admin_user} =
      Ipdth.Accounts.create_genesis_user(%{
        "email" => unique_admin_email(),
        "hashed_password" => "$2b$12$bXskhdRKbOOLc3vOJmn/s.4gXebk3jE/3.Z14TVgm6s4hhfxF0KRK"
      })

    admin_user
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Ipdth.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
