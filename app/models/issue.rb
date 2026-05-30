class Issue < ApplicationRecord
  belongs_to :user

  validates :number, presence: true, uniqueness: { scope: :user_id }
  validates :published_at, presence: true

  before_validation :assign_number, on: :create

  private

  def assign_number
    Issue.transaction do
      Issue.where(user: user).lock(true)
      self.number = (Issue.where(user: user).maximum(:number) || 0) + 1
    end
  end
end
