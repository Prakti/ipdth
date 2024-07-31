defmodule IpdthWeb.Router do
  use IpdthWeb, :router

  import IpdthWeb.AuthN

  @content_security_policy "default-src 'self';img-src 'self' blob: data:;"

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IpdthWeb.Layouts, :root}
    plug :protect_from_forgery

    plug(
      :put_secure_browser_headers,
      %{"content-security-policy" => @content_security_policy}
    )

    plug(:fetch_current_user)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", IpdthWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ipdth, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: IpdthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", IpdthWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{IpdthWeb.AuthN, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", IpdthWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{IpdthWeb.AuthN, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/users/:id/edit_roles", UserLive.Index, :edit_roles

      # Global Agent Management
      # TODO: 2021-01-21 - Create permission to globally edit agents (Admin)
      live "/agents/new", AgentLive.Index, :new
      live "/agents/:id/edit", AgentLive.Index, :edit
      live "/agents/:id/show/edit", AgentLive.Show, :edit
      live "/agents/:id/show/signup", AgentLive.Signup, :signup

      # Tournament Management
      live "/tournaments/new", TournamentLive.Index, :new
      live "/tournaments/:id/edit", TournamentLive.Index, :edit
      live "/tournaments/:id/show/edit", TournamentLive.Show, :edit
      live "/tournaments/:id/show/signup", TournamentLive.Signup, :edit
    end
  end

  scope "/", IpdthWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{IpdthWeb.AuthN, :mount_current_user}] do
      # Dashboard for Anon User
      live "/", DashboardLive

      # Global List and View of Agents
      live "/agents", AgentLive.Index, :index
      live "/agents/:id", AgentLive.Show, :show

      # Global List and View of Tournaments
      live "/tournaments", TournamentLive.Index, :index
      live "/tournaments/:id", TournamentLive.Show, :show
      live "/tournaments/:id/matches", TournamentLive.ListMatches, :index
      live "/tournaments/:tournament_id/matches/:match_id", TournamentLive.ShowMatch, :index

      # Global List and View of Users
      live "/users", UserLive.Index, :index

      # User Confirmation URLs for Signup and Password or E-Mail Change
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
