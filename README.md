# DOOMSCROLL

Turn your RSS into a beautifully formatted print-at-home zine. Less scroll. More soul.

## Installation

```
bundle install
bun install

cp .env.example .env

./bin/dev
```

## Environment

`.env.example` is committed as a template listing every variable the app reads. Copy it to `.env` and fill in values for local development or production deployment.

## Self Hosting

Doomscroll can be self hosted on your server of choice. We use Kamal to deploy.

### How it works

Every day, we run a job to check if your zine needs generating. If it's your delivery, we create a pool of articles from all your feeds since your last issue. We then drop low quality articles from the pool, randomise the remaining candidates, and create your issue.

Your issue then gets delivered to your via your chosen delivery mechanism. We currently support the following delivery options:

- Email - configure your SMTP server of choice in your environment variables
- Telegram - configure your bot token and chat ID in either the environment variables, or your preferences
- None - we'll still generate your issue, you just check it manually. Add a reminder in your calendar.

### Single user

A self hosted instance supports exactly one account:

- Until an account exists, the root path shows the sign up page.
- Once an account exists, sign up is automatically disabled and the root path shows the login page instead.

Setting `ENABLE_REGISTRATION=false` lets you force sign up off manually, e.g. while you're still finishing server setup and don't want anyone racing you to create the first account.

### Required environment variables

At minimum you'll need to set:

- `SECRET_KEY_BASE` — generate one with `bin/rails secret`.
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` — generate with `bin/rails db:encryption:init`. Used to encrypt secrets stored in the database, like a Telegram bot token entered in preferences.

If using email as the delivery method:

- `MAILER_DEFAULT_URL_HOST` (and `MAILER_DEFAULT_URL_PORT` if not 80/443) — used to build links in emails.
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD` — required to send the account confirmation email. You get a 2 day grace period to confirm before sign in is blocked.

If using Telegram as the delivery method:

`TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are optional — set both to offer Telegram as a ready-to-go zine delivery channel, or leave them blank and let the reader set their own bot token and chat id in onboarding or preferences instead.

## Deploy

Kamal loads `.env` automatically, so fill it in with your production secrets and deploy:

```
dotenv kamal deploy
```

## Contributing

Contributions are welcome! Please keep them short and descriptive, no 50 file rewrites. I know I've vibe coded a lot of this as a hobby project, but PRs should be descriptive and prioritise code quality going forward. 
