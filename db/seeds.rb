# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
return if Rails.env.production?

# user = User.find_or_create_by!(email: "test@test.com") do |u|
#   u.password = "test1234"
#   u.password_confirmation = "test1234"
#   u.terms_and_conditions = true
#   u.admin = true
# end
#
# user.confirm unless user.confirmed?

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

# User.first.issues.create! if User.first.issues.none?
