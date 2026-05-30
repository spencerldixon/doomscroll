class Feed < ApplicationRecord
  has_many :user_feeds, dependent: :delete_all
  has_many :users, through: :user_feeds

  scope :curated, -> { where(private: false).order(:name) }

  validates :name, :url, presence: true

  def self.normalize_domain(host)
    host.to_s.sub(/\Awww\./, "").downcase
  end

  def favicon_domain
    domain.presence || Feed.normalize_domain(URI.parse(url).host)
  rescue URI::InvalidURIError
    nil
  end
end
