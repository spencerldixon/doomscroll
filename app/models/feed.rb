class Feed < ApplicationRecord
  has_many :user_feeds, dependent: :delete_all
  has_many :users, through: :user_feeds

  # Enum for quality ratings
  attribute :quality, :string
  enum :quality, {
    unknown: "unknown",
    empty: "empty",
    partial: "partial",
    full: "full"
  }, default: "unknown"

  # Scopes
  scope :curated, -> { where(public: true) }
  # scope :private, -> { where(private: true) }

  # Validations
  validates :url, presence: true
end
