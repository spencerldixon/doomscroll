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

user = User.find_or_create_by!(email: "test@test.com") do |u|
  u.password = "test1234"
  u.password_confirmation = "test1234"
  u.terms_and_conditions = true
  u.admin = true
end

user.confirm unless user.confirmed?

feeds = [
  {
    name: "The Verge",
    url: "https://www.theverge.com/rss/index.xml",
    description: "Tech, science, art, and culture.",
    icon_url: "https://www.google.com/s2/favicons?domain=theverge.com&sz=64"
  },
  {
    name: "Hacker News",
    url: "https://news.ycombinator.com/rss",
    description: "Links for the intellectually curious.",
    icon_url: "https://www.google.com/s2/favicons?domain=news.ycombinator.com&sz=64"
  },
  {
    name: "Ars Technica",
    url: "https://feeds.arstechnica.com/arstechnica/index",
    description: "In-depth tech news and reviews.",
    icon_url: "https://www.google.com/s2/favicons?domain=arstechnica.com&sz=64"
  },
  {
    name: "Wired",
    url: "https://www.wired.com/feed/rss",
    description: "Technology and how it changes everything.",
    icon_url: "https://www.google.com/s2/favicons?domain=wired.com&sz=64"
  },
  {
    name: "404 Media",
    url: "https://www.404media.co/rss/",
    description: "Investigative tech journalism.",
    icon_url: "https://www.google.com/s2/favicons?domain=404media.co&sz=64"
  },
  {
    name: "Defector",
    url: "https://defector.com/feed",
    description: "Sports and culture by the people who cover it.",
    icon_url: "https://www.google.com/s2/favicons?domain=defector.com&sz=64"
  },
  {
    name: "Colossal",
    url: "https://www.thisiscolossal.com/feed/",
    description: "Art, design, and visual culture.",
    icon_url: "https://www.google.com/s2/favicons?domain=thisiscolossal.com&sz=64"
  },
  {
    name: "Pitchfork",
    url: "https://pitchfork.com/rss/news/",
    description: "Music news and reviews.",
    icon_url: "https://www.google.com/s2/favicons?domain=pitchfork.com&sz=64"
  },
  {
    name: "The Atlantic",
    url: "https://www.theatlantic.com/feed/all/",
    description: "Ideas, politics, and culture.",
    icon_url: "https://www.google.com/s2/favicons?domain=theatlantic.com&sz=64"
  }
]

feeds.each do |attrs|
  Feed.find_or_create_by!(url: attrs[:url]) do |f|
    f.name = attrs[:name]
    f.description = attrs[:description]
    f.icon_url = attrs[:icon_url]
  end
end
