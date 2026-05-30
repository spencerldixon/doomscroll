# Feeds Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `/feeds` page where users can browse/subscribe/unsubscribe from curated feeds and add private custom feeds by URL.

**Architecture:** `FeedsController` + `UserFeedsController` backed by a `private` boolean on `Feed`. Subscribe/unsubscribe redirect via Turbo Drive. Custom feed URLs enqueue `FeedFetchJob` which parses RSS/Atom metadata with Nokogiri. Client-side filtering uses a new `filter` Stimulus controller.

**Tech Stack:** Rails 8, Stimulus, Turbo Drive, Nokogiri (already in Gemfile.lock), Solid Queue (already configured)

---

### Task 1: Migration — add `private` to feeds

**Files:**
- Create: `db/migrate/TIMESTAMP_add_private_to_feeds.rb`

- [ ] **Step 1: Generate migration**

```bash
bin/rails generate migration AddPrivateToFeeds private:boolean
```

- [ ] **Step 2: Edit the generated migration to set default + null constraint**

Open the generated file in `db/migrate/` and ensure it reads:

```ruby
class AddPrivateToFeeds < ActiveRecord::Migration[8.1]
  def change
    add_column :feeds, :private, :boolean, default: false, null: false
  end
end
```

- [ ] **Step 3: Run migration**

```bash
bin/rails db:migrate
```

Expected: migration runs cleanly, `schema.rb` gains `t.boolean "private", default: false, null: false` in the feeds table.

---

### Task 2: Update Feed model

**Files:**
- Modify: `app/models/feed.rb`

- [ ] **Step 1: Add scope and update model**

Replace the entire content of `app/models/feed.rb` with:

```ruby
class Feed < ApplicationRecord
  has_many :user_feeds
  has_many :users, through: :user_feeds

  scope :curated, -> { where(private: false).order(:name) }

  validates :name, :url, presence: true
end
```

---

### Task 3: Add routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Add feeds and user_feeds resources**

In `config/routes.rb`, add after `resource :preferences, only: [:show, :update]`:

```ruby
resources :feeds, only: [:index, :create]
resources :user_feeds, only: [:create, :destroy], param: :feed_id
```

- [ ] **Step 2: Verify routes**

```bash
bin/rails routes | grep -E "feeds|user_feeds"
```

Expected output includes:
```
      feeds GET    /feeds(.:format)               feeds#index
            POST   /feeds(.:format)               feeds#create
 user_feeds POST   /user_feeds(.:format)          user_feeds#create
  user_feed DELETE /user_feeds/:feed_id(.:format) user_feeds#destroy
```

---

### Task 4: FeedsController

**Files:**
- Create: `app/controllers/feeds_controller.rb`

- [ ] **Step 1: Create controller**

Create `app/controllers/feeds_controller.rb`:

```ruby
class FeedsController < ApplicationController
  def index
    @curated_feeds = Feed.curated
    @user_feed_ids = current_user.feed_ids.to_set
    @user_feeds = current_user.user_feeds.includes(:feed).order("feeds.name")
  end

  def create
    url = params[:url].to_s.strip

    begin
      uri = URI.parse(url)
      raise ArgumentError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError, ArgumentError
      redirect_to feeds_path, alert: "Please enter a valid http/https URL." and return
    end

    feed = Feed.create!(url: url, name: url, private: true)
    current_user.user_feeds.create!(feed_id: feed.id)
    FeedFetchJob.perform_later(feed.id)
    redirect_to feeds_path, notice: "Feed added — we're fetching its details."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to feeds_path, alert: e.message
  end
end
```

---

### Task 5: UserFeedsController

**Files:**
- Create: `app/controllers/user_feeds_controller.rb`

- [ ] **Step 1: Create controller**

Create `app/controllers/user_feeds_controller.rb`:

```ruby
class UserFeedsController < ApplicationController
  def create
    feed = Feed.find(params[:feed_id])
    current_user.user_feeds.find_or_create_by(feed_id: feed.id)
    redirect_to feeds_path, notice: "Subscribed to #{feed.name}."
  end

  def destroy
    feed = Feed.find(params[:feed_id])
    current_user.user_feeds.where(feed_id: feed.id).delete_all
    redirect_to feeds_path, notice: "Unsubscribed from #{feed.name}."
  end
end
```

---

### Task 6: FeedFetchJob

**Files:**
- Create: `app/jobs/feed_fetch_job.rb`

- [ ] **Step 1: Create job**

Create `app/jobs/feed_fetch_job.rb`:

```ruby
class FeedFetchJob < ApplicationJob
  queue_as :default

  def perform(feed_id)
    feed = Feed.find_by(id: feed_id)
    return unless feed

    uri = URI.parse(feed.url)
    response = Net::HTTP.get_response(uri)

    3.times do
      break unless response.is_a?(Net::HTTPRedirection)
      uri = URI.parse(response["location"])
      response = Net::HTTP.get_response(uri)
    end

    return unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!

    name = doc.at_xpath("//channel/title")&.text&.strip ||
           doc.at_xpath("//feed/title")&.text&.strip
    description = doc.at_xpath("//channel/description")&.text&.strip ||
                  doc.at_xpath("//feed/subtitle")&.text&.strip ||
                  doc.at_xpath("//feed/description")&.text&.strip

    feed.update(
      name: name.presence || feed.url,
      description: description.presence
    )
  rescue => e
    Rails.logger.warn("FeedFetchJob failed for feed #{feed_id}: #{e.message}")
  end
end
```

---

### Task 7: Filter Stimulus controller

**Files:**
- Create: `app/javascript/controllers/filter_controller.js`
- Modify: `app/javascript/controllers/index.js`

- [ ] **Step 1: Create filter controller**

Create `app/javascript/controllers/filter_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item"]

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.itemTargets.forEach(item => {
      const name = (item.dataset.name || "").toLowerCase()
      const description = (item.dataset.description || "").toLowerCase()
      item.hidden = query.length > 0 && !name.includes(query) && !description.includes(query)
    })
  }
}
```

- [ ] **Step 2: Register in index.js**

In `app/javascript/controllers/index.js`, add after the CountdownController lines:

```javascript
import FilterController from "./filter_controller"
application.register("filter", FilterController)
```

---

### Task 8: Views

**Files:**
- Create: `app/views/feeds/index.html.erb`
- Create: `app/views/feeds/_feed_card.html.erb`
- Create: `app/views/feeds/_user_feed_item.html.erb`

- [ ] **Step 1: Create feed card partial**

Create `app/views/feeds/_feed_card.html.erb`:

```erb
<div
  id="feed_<%= feed.id %>"
  data-filter-target="item"
  data-name="<%= feed.name %>"
  data-description="<%= feed.description %>"
  class="flex flex-col items-center gap-2 p-3 border border-border rounded-lg aspect-[3/4]"
>
  <div class="flex-1 flex items-center justify-center w-full">
    <img
      src="https://www.google.com/s2/favicons?domain=<%= URI.parse(feed.url).host rescue feed.url %>&sz=64"
      alt="<%= feed.name %>"
      class="w-10 h-10 rounded object-contain"
    >
  </div>
  <div class="w-full space-y-0.5 text-center">
    <p class="text-xs font-semibold truncate leading-tight"><%= feed.name %></p>
    <p class="text-[10px] text-muted-foreground truncate"><%= URI.parse(feed.url).host rescue feed.url %></p>
  </div>
  <div class="w-full mt-auto">
    <% if subscribed %>
      <%= button_to user_feed_path(feed.id), method: :delete, class: "w-full btn text-xs py-1" do %>
        Subscribed
      <% end %>
    <% else %>
      <%= button_to user_feeds_path, params: { feed_id: feed.id }, class: "w-full btn-outline text-xs py-1" do %>
        + Subscribe
      <% end %>
    <% end %>
  </div>
</div>
```

- [ ] **Step 2: Create user feed item partial**

Create `app/views/feeds/_user_feed_item.html.erb`:

```erb
<div class="flex items-center justify-between p-3 border border-border rounded-lg">
  <div class="flex items-center gap-3">
    <img
      src="https://www.google.com/s2/favicons?domain=<%= URI.parse(feed.url).host rescue feed.url %>&sz=32"
      alt="<%= feed.name %>"
      class="w-6 h-6 rounded object-contain"
    >
    <div>
      <p class="text-sm font-semibold"><%= feed.name %></p>
      <p class="text-xs text-muted-foreground"><%= URI.parse(feed.url).host rescue feed.url %></p>
    </div>
  </div>
  <%= button_to user_feed_path(feed.id), method: :delete, class: "btn-outline text-xs py-1 px-3" do %>
    Remove
  <% end %>
</div>
```

- [ ] **Step 3: Create index view**

Create `app/views/feeds/index.html.erb`:

```erb
<%= render "shared/header", title: "Feeds", subtitle: "Manage your feed subscriptions" do %>
<% end %>

<div class="max-w-5xl mx-auto px-4 space-y-12">

  <div class="space-y-4">
    <h2 class="text-xl font-semibold vt">Your Feeds</h2>
    <% if @user_feeds.empty? %>
      <p class="text-muted-foreground text-sm">No feeds yet. Subscribe below or add a custom feed.</p>
    <% else %>
      <div class="space-y-2" id="user_feeds_list">
        <% @user_feeds.each do |user_feed| %>
          <%= render "feeds/user_feed_item", feed: user_feed.feed %>
        <% end %>
      </div>
    <% end %>
  </div>

  <div class="space-y-4">
    <h2 class="text-xl font-semibold vt">Add a custom feed</h2>
    <p class="text-muted-foreground text-sm">Paste any RSS or Atom URL. We'll fetch the details in the background.</p>
    <%= form_with url: feeds_path, method: :post, class: "flex gap-3" do |f| %>
      <input type="url" name="url" placeholder="https://example.com/feed.xml" class="input flex-1" required>
      <button type="submit" class="btn-primary">Add</button>
    <% end %>
  </div>

  <div class="space-y-4" data-controller="filter">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <h2 class="text-xl font-semibold vt">Discover</h2>
      <input
        data-filter-target="input"
        data-action="input->filter#filter"
        type="text"
        placeholder="Search feeds..."
        class="input w-full sm:w-64"
      >
    </div>
    <% if @curated_feeds.empty? %>
      <p class="text-muted-foreground text-sm">No curated feeds available yet.</p>
    <% else %>
      <div class="grid grid-cols-3 sm:grid-cols-5 lg:grid-cols-9 gap-3">
        <% @curated_feeds.each do |feed| %>
          <%= render "feeds/feed_card", feed: feed, subscribed: @user_feed_ids.include?(feed.id) %>
        <% end %>
      </div>
    <% end %>
  </div>

</div>
```

---

### Task 9: Update navbar

**Files:**
- Modify: `app/views/shared/_navbar.html.erb`

- [ ] **Step 1: Update the Feeds link**

In `app/views/shared/_navbar.html.erb`, find:

```erb
      <%= link_to root_path do %>
        Feeds
      <% end %>
```

Replace with:

```erb
      <%= link_to feeds_path do %>
        Feeds
      <% end %>
```

- [ ] **Step 2: Verify app boots**

```bash
bin/rails runner "puts 'ok'"
```

Expected: `ok`
