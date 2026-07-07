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

We set `SELF_HOSTED=true` to determine a self hosted instance and toggle on/off features like subscriptions and telegram notifications (toggled off in self hosted mode).

Setting `ENABLE_REGISTRATION=false` will disable new user sign ups.

## Contributing

Contributions are welcome! Please keep them short and descriptive, no 50 file rewrites. I know I've vibe coded a lot of this as an initial hobby project, but PRs should be descriptive and prioritise code quality going forward. 
