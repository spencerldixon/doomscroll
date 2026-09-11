# DOOMSCROLL

Takes your RSS feeds and turns them into a beautifully formatted print-at-home zine.

## Installation

```
bundle install
bun install

./bin/dev
```

## Environment

Public, non-secret sensible defaults live in `.env`, we commit this as guidance to follow and override.

Use `.env.development.local` or `.env.production.local` to set overrides and store any secrets. These are gitignored.


## Self Hosting

Doomscroll can be self hosted on your server of choice. We use Kamal to deploy.

Set `SELF_HOSTED=true` to mark the instance as self hosted.

### Single user

A self hosted instance supports exactly one account:

- Until an account exists, the root path shows the sign up page.
- Once an account exists, sign up is automatically disabled and the root path shows the login page instead.

Setting `ENABLE_REGISTRATION=false` lets you force sign up off manually, e.g. while you're still finishing server setup and don't want anyone racing you to create the first account.

### Required environment

At minimum you'll need to set:

- `SECRET_KEY_BASE` — generate one with `bin/rails secret`.
- `MAILER_DEFAULT_URL_HOST` (and `MAILER_DEFAULT_URL_PORT` if not 80/443) — used to build links in emails.
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD` — required to send the account confirmation email. You get a 2 day grace period to confirm before sign in is blocked.

`TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are optional — leave them blank to skip Telegram notifications for sign ups and production error reports, or set both to enable them.

## Deploy

You can use dotenv to set secrets and deploy via kamal

```
dotenv -f .env.production.local,.env kamal deploy
```

## Contributing

Contributions are welcome! Please keep them short and descriptive, no 50 file rewrites. I know I've vibe coded a lot of this as an initial hobby project, but PRs should be descriptive and prioritise code quality going forward. 
