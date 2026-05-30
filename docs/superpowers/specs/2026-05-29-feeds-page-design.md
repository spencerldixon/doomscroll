# Feeds Page Design

**Date:** 2026-05-29
**Status:** Approved

## Overview

A `/feeds` page where authenticated users can browse admin-curated feeds, subscribe/unsubscribe, and add custom RSS feeds by URL. Custom feeds are marked private and fetched in the background.

## Scope

- Browse curated (public) feeds with subscribe/unsubscribe
- Filter curated feeds client-side by name/description
- Add custom feed by URL → background job fetches metadata
- Custom feeds are private (not shown in curated list to other users)
- Remove any subscribed feed (curated or private)

## Data Model Changes

### Feed — add `private` column

```ruby
add_column :feeds, :private, :boolean, default: false, null: false
```

Public feeds (`private: false`) appear in the curated browse list for all users. Private feeds (`private: true`) are user-submitted and only visible to the subscribing user.

## Architecture

### Routes

```ruby
resources :feeds, only: [:index, :create]
resources :user_feeds, only: [:create, :destroy]
```

Produces:
- `GET  /feeds`             → `feeds#index`
- `POST /feeds`             → `feeds#create` (custom URL submission)
- `POST /user_feeds`        → `user_feeds#create` (subscribe to curated feed)
- `DELETE /user_feeds/:id`  → `user_feeds#destroy` (unsubscribe)

### FeedsController

**`index`:**
- `@curated_feeds` = `Feed.where(private: false).order(:name)`
- `@user_feed_ids` = `current_user.feed_ids` (Set for O(1) lookup in view)
- `@user_feeds` = `current_user.user_feeds.includes(:feed)` (for "Your Feeds" section)

**`create`:**
- Params: `url` (string, required)
- Validate URL format (URI parse, require http/https scheme)
- Create `Feed` with `url:`, `private: true`, placeholder `name: url` (job will update)
- Create `UserFeed` linking current user to the new feed
- Enqueue `FeedFetchJob.perform_later(feed.id)`
- On success: redirect to `feeds_path` with notice "Feed added — we're fetching its details."
- On invalid URL: redirect back with alert

### UserFeedsController

**`create`:**
- Params: `feed_id`
- `current_user.user_feeds.find_or_create_by(feed_id: params[:feed_id])`
- Responds to Turbo Stream: replaces the subscribe button with unsubscribe button for that feed card
- Falls back to redirect to `feeds_path`

**`destroy`:**
- Finds `UserFeed` scoped to `current_user` (prevents unauthorized deletion)
- Destroys record
- Responds to Turbo Stream: replaces the unsubscribe button with subscribe button
- Falls back to redirect to `feeds_path`

### FeedFetchJob

New background job `app/jobs/feed_fetch_job.rb`:
- Receives `feed_id`
- Fetches URL with `Net::HTTP` (follow redirects, 10s timeout)
- Parses RSS/Atom with `Nokogiri` (already in Rails stack)
  - Title: `//channel/title` (RSS) or `//feed/title` (Atom)
  - Description: `//channel/description` or `//feed/subtitle`
- Updates `Feed` record with parsed `name` and `description`
- Does NOT fetch or store `icon_url` — icons assembled at render time via `FeedsHelper#feed_icon_url(feed)` using the feed's domain (e.g. Google favicon service)
- On fetch/parse error: logs warning, leaves feed with URL as name (non-fatal)

### View — `feeds/index.html.erb`

Two sections:

**1. Your Feeds** — list of `@user_feeds` with feed name + unsubscribe button. Empty state if none.

**2. Discover** — grid of `@curated_feeds` cards. Each card shows name + description. If subscribed (`@user_feed_ids.include?(feed.id)`), show unsubscribe button; else show subscribe button. Stimulus `filter` controller provides client-side name/description search.

**3. Add custom feed** — small form at bottom: URL text input + submit. Posts to `feeds_path`.

### Stimulus Filter Controller

New controller `app/javascript/controllers/filter_controller.js`:
- Targets: `input` (search field), `item` (each feed card)
- On input event: downcases query, hides items where neither `data-name` nor `data-description` contains query
- No debounce needed (client-side DOM filter is instant)

### Navigation

Update "Feeds" `link_to` in `_navbar.html.erb` to point to `feeds_path`.

## Error Handling

- Invalid URL on custom feed submit: redirect back with flash alert "Please enter a valid http/https URL."
- `FeedFetchJob` failure: non-fatal, feed record stays with URL as name, job logs error
- `UserFeedsController#destroy` scoped to `current_user` — 404 if user tries to delete another user's subscription

## Out of Scope

- Pagination of curated feeds (assume manageable count for now)
- Editing custom feed metadata
- Feed health checks / dead feed detection
- Admin feed management UI
