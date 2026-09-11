## Seed example feeds

feeds = YAML.load_file(Rails.root.join("db", "feeds.yml")).fetch("feeds")

feeds.each do |entry|
  feed = Feed.find_or_initialize_by(url: entry.fetch("url"))
  feed.public = true
  feed.category = entry["category"]
  feed.save!

  FeedDiscoverJob.perform_later(feed) if feed.unknown?
rescue StandardError => e
  # The discover job destroys feeds it can't validate; don't let one dead
  # feed abort the rest of the seed.
  Rails.logger.warn "[seeds] skipping feed #{entry["url"]}: #{e.message}"
end

## Seed user in development only

if Rails.env.development?
  user = User.find_or_create_by!(email: "test@test.com") do |u|
    u.password = "test1234"
    u.password_confirmation = "test1234"
  end
end
