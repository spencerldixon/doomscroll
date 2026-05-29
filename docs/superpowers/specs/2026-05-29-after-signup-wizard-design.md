# After Signup Wizard Design

**Date:** 2026-05-29

## Overview

3-step onboarding wizard using Wicked gem. Runs after every new signup (email/password and Google OAuth). Collects zine name, feed selections, and delivery day. Data persisted to `zine_preferences` and `user_feeds` join table.

---

## Data Layer

### New tables

```
feeds
  id            bigint PK
  name          string  (e.g. "The Verge")
  url           string  (e.g. "https://www.theverge.com/rss/index.xml")
  description   text
  icon_url      string  (explicit URL or blank → fallback to Google favicon service)
  created_at    datetime
  updated_at    datetime

user_feeds
  user_id       bigint FK → users
  feed_id       bigint FK → feeds
  (no id column — pure join table)

zine_preferences
  id            bigint PK
  user_id       bigint FK → users (unique index)
  zine_name     string
  delivery_day  integer  (0=Sunday … 6=Saturday, maps to Ruby Date::DAYNAMES)
  created_at    datetime
  updated_at    datetime
```

### Model associations

```ruby
# User
has_one  :zine_preference
has_many :user_feeds
has_many :feeds, through: :user_feeds

# ZinePreference
belongs_to :user

# Feed
has_many :user_feeds
has_many :users, through: :user_feeds

# UserFeed (join)
belongs_to :user
belongs_to :feed
```

### Seed data

`db/seeds.rb` seeded with ~9 example RSS feeds including name, url, description, icon_url. Structure allows easy addition of remaining feeds.

---

## Routing

```ruby
resources :after_signup, only: [:show, :update]
```

Wicked maps:
- `GET  /after_signup/:id` → `show`
- `PATCH /after_signup/:id` → `update`

Steps: `:name` → `:feeds` → `:delivery` → finish

---

## Controller

`AfterSignupController`:

- `before_action :authenticate_user!` (inherited from ApplicationController)
- `show`: assigns `@user = current_user`, builds `@zine_preference` for `:name` step, loads `@feeds` for `:feeds` step, renders via `render_wizard`
- `update`: per-step params, saves, advances with `render_wizard`

### Per-step update logic

| Step | Params | Action |
|------|--------|--------|
| `:name` | `zine_name` | Find/create `ZinePreference`, update `zine_name` |
| `:feeds` | `feed_ids[]` | Replace `user.feeds` with selected IDs (`user.feed_ids = params[:feed_ids]`) |
| `:delivery` | `delivery_day` | Update `ZinePreference#delivery_day` |

On finish: `redirect_to wizard_path(:wicked_finish)` → renders summary view, then user clicks through to `authenticated_root_path`.

---

## Signup Redirect Hook

### Email/password signup

Override in `ApplicationController`:

```ruby
def after_sign_up_path_for(resource)
  after_signup_path(:name)
end
```

### Google OAuth new users

In `Users::OmniauthCallbacksController#google_oauth2`, detect first sign-in:

```ruby
if @user.persisted?
  sign_in @user, event: :authentication
  if @user.zine_preference.nil?
    redirect_to after_signup_path(:name)
  else
    redirect_to authenticated_root_path
  end
end
```

---

## Views

All wizard steps use `application.html.erb` layout with `content_for :body` to suppress sidebar (clean onboarding shell with just flash + centered content). Progress indicator at top (Step 1/2/3).

### Step 1 — `:name`

- Centered form
- Single text input: "What's your zine called?"
- Submit advances to `:feeds`

### Step 2 — `:feeds`

- 9×9 grid of portrait rectangle cards
- Each card: icon (center), name, URL, description
- Multi-select via Stimulus `feeds` controller:
  - Click toggles `.ring-2 ring-violet-500` highlight class
  - Maintains `<input type="hidden" name="feed_ids[]" value="...">` per selected feed
  - Hidden inputs added/removed on toggle
- Submit posts `feed_ids[]` array

### Step 3 — `:delivery`

- 7 day-of-week cards (Sun–Sat) in a row
- Single-select (radio style) via Stimulus
- Same card highlight pattern, deselects others on pick
- Submit posts `delivery_day` integer

### Finish view

- Summary: zine name, selected feed names, delivery day
- "Go to dashboard" → `authenticated_root_path`

---

## JavaScript

Single Stimulus controller `feeds_controller.js` handles both multi-select (step 2) and single-select (step 3) via a `multiple` value:

- Targets: `card` (each selectable card), `container` (hidden inputs mount point)
- On card click: toggle selected state, sync hidden inputs
- Single-select mode: deselect all others before selecting clicked card

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `db/migrate/..._create_feeds.rb` | Create |
| `db/migrate/..._create_user_feeds.rb` | Create |
| `db/migrate/..._create_zine_preferences.rb` | Create |
| `db/seeds.rb` | Update with feed seed data |
| `app/models/feed.rb` | Create |
| `app/models/user_feed.rb` | Create |
| `app/models/zine_preference.rb` | Create |
| `app/models/user.rb` | Add associations |
| `app/controllers/after_signup_controller.rb` | Implement show/update |
| `app/controllers/application_controller.rb` | Add `after_sign_up_path_for` |
| `app/controllers/users/omniauth_callbacks_controller.rb` | Redirect new users |
| `config/routes.rb` | Add `resources :after_signup` |
| `app/views/after_signup/name.html.erb` | Create |
| `app/views/after_signup/feeds.html.erb` | Create |
| `app/views/after_signup/delivery.html.erb` | Create |
| `app/views/after_signup/wicked_finish.html.erb` | Create |
| `app/javascript/controllers/feeds_controller.js` | Create |
