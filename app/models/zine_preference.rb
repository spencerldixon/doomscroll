class ZinePreference < ApplicationRecord
  belongs_to :user

  validates :user, uniqueness: true
  validates :delivery_day, presence: true
  validates :zine_name, presence: true
end
