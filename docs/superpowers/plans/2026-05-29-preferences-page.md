# Preferences Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `/preferences` page where authenticated users can update their zine name and delivery day.

**Architecture:** Singular resource route `resource :preferences` maps to a new `PreferencesController` with `show`/`update` actions. `update` patches `current_user.zine_preference` directly. View reuses existing `selection` Stimulus controller for the day picker, with server-side pre-selection via CSS class + hidden input.

**Tech Stack:** Rails 8, Minitest, Devise (auth), Tailwind CSS, Stimulus JS (`selection` controller already registered)

---

### Task 1: Add route and stub controller

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/preferences_controller.rb`

- [ ] **Step 1: Add singular resource route**

In `config/routes.rb`, add before the `get "up"` line:

```ruby
resource :preferences, only: [:show, :update]
```

- [ ] **Step 2: Create stub controller**

Create `app/controllers/preferences_controller.rb`:

```ruby
class PreferencesController < ApplicationController
  def show
    @zine_preference = current_user.zine_preference
  end

  def update
    @zine_preference = current_user.zine_preference
    if @zine_preference.update(zine_name: params[:zine_name], delivery_day: params[:delivery_day])
      redirect_to preferences_path, notice: "Preferences saved."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
```

- [ ] **Step 3: Verify routes exist**

Run: `bin/rails routes | grep preferences`

Expected output includes:
```
preferences  GET   /preferences(.:format)  preferences#show
             PATCH /preferences(.:format)  preferences#update
             PUT   /preferences(.:format)  preferences#update
```

---

### Task 2: Write controller tests

**Files:**
- Create: `test/controllers/preferences_controller_test.rb`
- Modify: `test/fixtures/users.yml`

- [ ] **Step 1: Add a confirmed user fixture with zine_preference**

In `test/fixtures/users.yml`, replace the empty fixtures with:

```yaml
one:
  email: user@example.com
  encrypted_password: <%= BCrypt::Password.create('password') %>
  confirmed_at: <%= Time.now %>
  name: Test User
  admin: false
```

Create `test/fixtures/zine_preferences.yml`:

```yaml
one:
  user: one
  zine_name: "Test Zine"
  delivery_day: 1
```

- [ ] **Step 2: Write failing tests**

Create `test/controllers/preferences_controller_test.rb`:

```ruby
require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "GET /preferences renders show" do
    get preferences_path
    assert_response :success
  end

  test "PATCH /preferences updates zine_name" do
    patch preferences_path, params: { zine_name: "New Zine Name", delivery_day: 3 }
    assert_redirected_to preferences_path
    assert_equal "New Zine Name", @user.zine_preference.reload.zine_name
    assert_equal 3, @user.zine_preference.reload.delivery_day
  end

  test "PATCH /preferences with blank zine_name re-renders show" do
    patch preferences_path, params: { zine_name: "", delivery_day: 1 }
    assert_response :unprocessable_entity
  end

  test "GET /preferences redirects unauthenticated user" do
    sign_out @user
    get preferences_path
    assert_redirected_to new_user_session_path
  end
end
```

- [ ] **Step 3: Run tests — expect failures (no view yet)**

Run: `bin/rails test test/controllers/preferences_controller_test.rb`

Expected: Tests for show/update fail with `ActionController::UnknownFormat` or missing template — that's correct, the view doesn't exist yet. The redirect test should pass.

---

### Task 3: Build the preferences view

**Files:**
- Create: `app/views/preferences/show.html.erb`

- [ ] **Step 1: Create the view**

Create `app/views/preferences/show.html.erb`:

```erb
<%= render "shared/header", title: "Preferences", subtitle: "Update your zine settings" do %>
<% end %>

<div class="max-w-lg mx-auto px-4 space-y-10">
  <%= form_with url: preferences_path, method: :patch, class: "space-y-10" do |f| %>

    <%# Flash errors %>
    <% if @zine_preference.errors.any? %>
      <div class="text-red-500 text-sm space-y-1">
        <% @zine_preference.errors.full_messages.each do |msg| %>
          <p><%= msg %></p>
        <% end %>
      </div>
    <% end %>

    <%# Zine name %>
    <div class="space-y-3">
      <h2 class="text-xl font-semibold vt">Zine name</h2>
      <div class="flex flex-col gap-3">
        <label class="label" for="zine_name">Name</label>
        <input
          id="zine_name"
          type="text"
          name="zine_name"
          value="<%= @zine_preference.zine_name %>"
          placeholder="Bob's Morning Doomscroll"
          class="w-full input"
          required
        >
      </div>
    </div>

    <%# Delivery day %>
    <div class="space-y-3">
      <h2 class="text-xl font-semibold vt">Delivery day</h2>
      <p class="text-muted-foreground text-sm">Which day of the week should your zine arrive?</p>
      <div
        data-controller="selection"
        data-selection-multiple-value="false"
        data-selection-name-value="delivery_day"
        class="grid grid-cols-7 gap-2"
      >
        <%# Pre-seed hidden input so current value is submitted if user doesn't click %>
        <% if @zine_preference.delivery_day.present? %>
          <input type="hidden" name="delivery_day" value="<%= @zine_preference.delivery_day %>" data-selection-target="input">
        <% end %>
        <% Date::DAYNAMES.each_with_index do |day, index| %>
          <div
            data-selection-target="card"
            data-id="<%= index %>"
            data-action="click->selection#toggle"
            class="flex flex-col items-center justify-center gap-1 p-3 border border-border rounded-lg cursor-pointer hover:border-violet-400 transition-all select-none aspect-square <%= 'selected' if @zine_preference.delivery_day == index %>"
          >
            <span class="text-xs font-semibold"><%= day[0..2] %></span>
          </div>
        <% end %>
      </div>
    </div>

    <div class="flex justify-end">
      <button type="submit" class="btn-primary">Save preferences</button>
    </div>

  <% end %>
</div>
```

- [ ] **Step 2: Run tests**

Run: `bin/rails test test/controllers/preferences_controller_test.rb`

Expected: All 4 tests pass.

---

### Task 4: Update navbar Settings link

**Files:**
- Modify: `app/views/shared/_navbar.html.erb`

- [ ] **Step 1: Update the Settings link**

In `app/views/shared/_navbar.html.erb`, find:

```erb
      <%= link_to root_path do %>
        Settings
      <% end %>
```

Replace with:

```erb
      <%= link_to preferences_path do %>
        Settings
      <% end %>
```

- [ ] **Step 2: Verify app boots and page loads**

Run: `bin/rails test test/controllers/preferences_controller_test.rb`

Expected: Still all green.
