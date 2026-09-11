class ZinePreference < ApplicationRecord
  DELIVERY_INTERVAL_DAYS = { "weekly" => 7, "biweekly" => 14, "monthly" => 28 }.freeze

  DELIVERY_FREQUENCY_LABELS = {
    "weekly" => "Every week",
    "biweekly" => "Every 2 weeks",
    "monthly" => "Every 4 weeks"
  }.freeze

  belongs_to :user

  enum :delivery_frequency, DELIVERY_INTERVAL_DAYS.keys.index_by(&:itself), validate: true

  validates :user, uniqueness: true
  validates :zine_name, presence: true
  validates :delivery_day, inclusion: { in: 0..6 }, allow_nil: true

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
end
