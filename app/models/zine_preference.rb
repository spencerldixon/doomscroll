class ZinePreference < ApplicationRecord
  DELIVERY_INTERVAL_DAYS = { "weekly" => 7, "biweekly" => 14, "monthly" => 28 }.freeze

  DELIVERY_FREQUENCY_LABELS = {
    "weekly" => "Every week",
    "biweekly" => "Every 2 weeks",
    "monthly" => "Every 4 weeks"
  }.freeze

  DELIVERY_METHODS = %w[email telegram].freeze

  belongs_to :user

  encrypts :telegram_bot_token

  enum :delivery_frequency, DELIVERY_INTERVAL_DAYS.keys.index_by(&:itself), validate: true

  validates :user, uniqueness: true
  validates :zine_name, presence: true
  validates :delivery_day, inclusion: { in: 0..6 }, allow_nil: true
  validates :delivery_method, inclusion: { in: DELIVERY_METHODS }
  validate :telegram_credentials_present, if: -> { delivery_method == "telegram" }

  # Picking a new cadence restarts the cycle from today, so the countdown
  # responds to the change even for a reader with no delivery on record.
  before_save :restart_delivery_cycle, if: -> { persisted? && delivery_frequency_changed? }

  def delivery_interval_days
    DELIVERY_INTERVAL_DAYS.fetch(delivery_frequency)
  end

  def due_on?(date)
    return false unless delivery_day == date.wday

    last_delivered_on.nil? || last_delivered_on <= date - delivery_interval_days
  end

  private

  def restart_delivery_cycle
    self.last_delivered_on = Date.current
  end

  def telegram_credentials_present
    return if DeliveryChannels.telegram_available?
    return if telegram_bot_token.present? && telegram_chat_id.present?

    errors.add(:base, "Add a Telegram bot token and chat id, or configure TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID on the server")
  end
end
