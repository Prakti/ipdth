defmodule Ipdth.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_admin_email, do: "admin#{System.unique_integer()}@ipdth.com"
  def valid_user_password, do: "Das ist das Haus vom Nikolaus!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def valid_admin_attributes(attrs \\ %{}) do
    valid_user_attributes(attrs)
    |> Enum.into(%{roles: [:tournament_admin, :user_admin]})
  end

  def admin_user_fixture(attrs \\ %{}) do
    {:ok, admin_user} =
      attrs
      |> valid_admin_attributes()
      |> Ipdth.Accounts.seed_user()

    admin_user
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Ipdth.Accounts.seed_user()

    user
  end

  def user_list_fixture(user_count, admin_count) do
    %{
      users:
        Enum.map(1..user_count, fn n ->
          user_fixture(%{
            email: "user_#{n}@ipdth.org"
          })
        end),
      admins:
        Enum.map(1..admin_count, fn n ->
          admin_user_fixture(%{
            email: "admin_#{n}@ipdth.org"
          })
        end)
    }
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
