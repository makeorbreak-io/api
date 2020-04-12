defmodule Api.NotificationEmailsTest do
  use ApiWeb.ConnCase
  use Bamboo.Test

  alias Api.Notifications.Emails

  test "invite email" do
    host = create_user(%{
      name: "Random User",
      email: "host@example.com",
      password: "thisisapassword"
    })

    email = Emails.invite_email("email@example.com", host)

    assert email.to == "email@example.com"
    assert email.subject == "Join #{host.name}'s team in this year's Make or Break!"
  end

  test "registration email" do
    user = create_user(%{
      email: "user@example.com",
      password: "thisisapassword",
      name: "Random User",
    })

    email = Emails.registration_email(user)

    assert email.to == user
    assert email.subject == "Make or Break - You are almost there!"
  end
end
