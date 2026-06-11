class ZinePreference < ApplicationRecord
  belongs_to :user

  validates :user, uniqueness: true
  validates :zine_name, presence: true
  validates :delivery_day, inclusion: { in: 0..6 }, allow_nil: true
end
