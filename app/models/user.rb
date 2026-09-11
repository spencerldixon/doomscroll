class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable, :trackable

  has_one  :zine_preference, dependent: :destroy
  has_many :user_feeds, dependent: :destroy
  has_many :feeds, through: :user_feeds
  has_many :issues, dependent: :destroy

  validates :email, presence: true, 'valid_email_2/email': true

  def self.registration_enabled?
    return false if exists?

    ActiveModel::Type::Boolean.new.cast(ENV["ENABLE_REGISTRATION"].presence || true)
  end

  # Deliver Devise emails (confirmation, reset, etc.) through Active Job so a
  # slow or misconfigured mailer can't turn into a 500 on the request thread.
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def setup_complete?
    zine_preference&.zine_name.present? && zine_preference&.delivery_day.present? && user_feeds.any?
  end

  CADENCE_LABELS = {
    "weekly" => "Every %{day}",
    "biweekly" => "Every other %{day}",
    "monthly" => "Every 4 weeks on %{day}"
  }.freeze

  def next_issue_day
    Date::DAYNAMES[zine_preference&.delivery_day]
  end

  def delivery_cadence_label
    return nil unless zine_preference&.delivery_day

    format(CADENCE_LABELS.fetch(zine_preference.delivery_frequency), day: next_issue_day)
  end

  def days_until_next_issue
    return nil unless zine_preference&.delivery_day

    (next_issue_date - Date.current).to_i
  end

  # The next delivery_day that is at least one full interval on from the last
  # delivery. A user who has never been delivered to gets the next one outright.
  def next_issue_date
    return nil unless zine_preference&.delivery_day

    date = Date.current + ((zine_preference.delivery_day - Date.current.wday) % 7)
    date += 7 if date == Date.current

    if zine_preference.last_delivered_on
      earliest = zine_preference.last_delivered_on + zine_preference.delivery_interval_days
      date += 7 while date < earliest
    end

    date
  end
end
