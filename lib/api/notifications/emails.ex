defmodule Api.Notifications.Emails do
  use Bamboo.Phoenix, view: ApiWeb.EmailView

  alias Api.Accounts.User
  alias ApiWeb.LayoutView

  def invite_email(recipient, host) do
    base_email(recipient)
    |> subject("Join #{User.display_name(host)}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{User.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, User.display_name(host))
    |> assign(:name, recipient)
    |> assign(:email, recipient)
    |> render("invite.html")
  end

  def invite_notification_email(recipient, host) do
    base_email(recipient)
    |> subject("Join #{host.name}'s team in this year's Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Join #{User.display_name(host)}'s team in this year's Make or Break")
    |> assign(:host_name, User.display_name(host))
    |> assign(:name, User.display_name(recipient))
    |> assign(:email, recipient.email)
    |> render("invite_notification.html")
  end

  def registration_email(recipient) do
    base_email(recipient)
    |> subject("Make or Break - You are almost there!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("registration.html")
  end

  def joined_hackathon_email(recipient, team) do
    base_email(recipient)
    |> subject("You have applied to the Make or Break hackathon!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Your team's application is currently under review")
    |> assign(:name, User.display_name(recipient))
    |> assign(:team_name, team.name)
    |> render("hackathon.html")
  end

  def joined_event_email(recipient, event) do
    base_email(recipient)
    |> subject("You have applied to #{event.name}")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "You have applied to #{event.name}")
    |> assign(:name, User.display_name(recipient))
    |> assign(:event, event)
    |> render("event.html")
  end

  def checkin_email(recipient) do
    base_email(recipient)
    |> subject("Welcome to Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("checkin.html")
  end

  def recover_password_email(recipient) do
    base_email(recipient)
    |> subject("Reset your MoB password.")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Reset your password")
    |> assign(:name, User.display_name(recipient))
    |> assign(:token, recipient.pwd_recovery_token)
    |> render("recover_password.html")
  end

  def team_acceptance(recipient) do
    base_email(recipient)
    |> subject("Cheers, mate! You and your team are in Make or Break!")
    |> put_html_layout({LayoutView, "email.html"})
    |> assign(:title, "Welcome to Make or Break!")
    |> assign(:name, User.display_name(recipient))
    |> render("team_acceptance.html")
  end

  def send_email(email, recipient) do
    base_email(recipient)
    |> subject(email.subject)
    |> assign(:title, email.title)
    |> assign(:name, User.display_name(recipient))
    |> assign(:content, email.content)
    |> put_html_layout({LayoutView, "email.html"})
    |> render("email.html")
    |> premail()
  end

  defp base_email(recipient) do
    # Here you can set a default from, default headers, etc.
    new_email()
    |> from({"Make or Break", "info@makeorbreak.io"})
    |> to(recipient)
  end

  defp premail(email) do
    html = Premailex.to_inline_css(email.html_body)

    email
    |> html_body(html)
  end
end
