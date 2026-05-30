# Preferences Page Design

**Date:** 2026-05-29
**Status:** Approved

## Overview

Single-page preferences UI at `/preferences` allowing authenticated users to update their zine name and delivery day. Updates the existing `ZinePreference` record created during the after-signup wizard.

## Scope

- Zine name (string)
- Delivery day (integer 0–6, day of week)
- Feeds management is out of scope (separate page, future work)
- Account info (name, email, password) is out of scope

## Architecture

### Route

```ruby
resource :preferences, only: [:show, :update]
```

Produces:
- `GET  /preferences` → `preferences#show`
- `PATCH /preferences` → `preferences#update`

### Controller

New `PreferencesController < ApplicationController`:

- `show` — assigns `@zine_preference = current_user.zine_preference`
- `update` — updates `current_user.zine_preference` with permitted params (`zine_name`, `delivery_day`); on success redirect to `preferences_path` with notice; on failure re-render `show` with errors

Permitted params: `zine_name` (string), `delivery_day` (integer).

### Model

No model changes. `ZinePreference` already has `zine_name` and `delivery_day`. Record is guaranteed to exist for any user who completed the after-signup wizard. The `require_setup_complete!` before_action on `ApplicationController` ensures incomplete users are redirected to the wizard first.

### View

Single ERB template `app/views/preferences/show.html.erb`. Two sections within one `form_with` targeting the preferences resource:

1. **Zine Name** — text input pre-filled with `@zine_preference.zine_name`. Uses existing `label` + `input` CSS classes.
2. **Delivery Day** — 7-button grid (Monday–Sunday), pre-selected on `@zine_preference.delivery_day`. Reuses existing `selection` Stimulus controller (same pattern as `after_signup/delivery.html.erb`).

One submit button using `btn-primary` class. Flash message on successful save.

### Navigation

Update the "Settings" `link_to` in `app/views/shared/_navbar.html.erb` to point to `preferences_path` instead of `root_path`.

## Styling

Follows existing conventions:
- `vt` class for VT323 font headings
- `label`, `input` classes for form fields
- `btn`, `btn-primary` for buttons
- Lime-400 accents, violet-400 hover states
- Matches visual language of the after-signup wizard steps

## Error Handling

- Validation errors on `ZinePreference` render `show` with inline error messages
- `zine_name` presence is already validated on the model

## Out of Scope

- Feed subscription management (separate page)
- Account info / password change (Devise handles via existing route)
- Email notification preferences (not yet a feature)
