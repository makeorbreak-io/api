# API

## Setup guide

To start your Phoenix app:

- Install dependencies with `mix deps.get`
- Add the necessary variables to your environment
- Create and migrate your database with `mix ecto.create && mix ecto.migrate`
- Start Phoenix endpoint with `mix server`

## Deploy

We're using [edeliver](https://github.com/edeliver/edeliver). We're using cold
deploys, not upgrades.
The deployment process is done using the following commands:

- mix edeliver build release
- mix edeliver deploy release production
- mix edeliver restart production
- mix edeliver migrate production

Note that trying to stop the api from edeliver won't be too successfull as
systemd will notice its absence and restart it immediatly.

We try to preserve our deps' built files. If you need to clean those for
some reason, run `GIT_CLEAN_PATHS=. mix edeliver build release`.

## Environment Variables

Use your preferred method to add the following variables to your environment.
You can find an example env file you can source in `share/env/env`

| Variable             | Description                 | Environments |
| -------------------- | --------------------------- | ------------ |
| `AI_CALLBACK_URL`    | AI Competition callback url | All          |
| `AI_SERVER_HOST`     | AI Competition server host  | All          |
| `AI_SERVER_TOKEN`    | AI Competition access token | All          |
| `DATABASE_URL`       | Postgresql database url     | All          |
| `GITHUB_TOKEN`       | Github API access token     | All          |
| `HOST`               | Server url                  | All          |
| `MAILGUN_API_DOMAIN` | Mailgun API credentials     | Prod         |
| `MAILGUN_API_KEY`    | Mailgun API credentials     | Prod         |
| `PORT`               | Port configuration          | Prod         |
| `SECRET_KEY_BASE`    | Secret key base             | All          |
| `SENTRY_DSN`         | Sentry.io project url       | Prod         |
| `SLACK_TOKEN`        | Slack API access token      | Prod         |
