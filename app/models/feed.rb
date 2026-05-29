class Feed < ApplicationRecord
  has_many :user_feeds
  has_many :users, through: :user_feeds

  validates :name, :url, presence: true
end
