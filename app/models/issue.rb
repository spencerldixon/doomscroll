class Issue < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :number, presence: true, uniqueness: { scope: :user_id }
  validates :published_at, presence: true

  before_validation :set_issue_title,  on: :create
  before_validation :set_issue_number, on: :create

  private

  def set_issue_title
    self.name = user.zine_preference&.zine_name || "Doomscroll"
  end

  def set_issue_number
    Issue.transaction do
      Issue.where(user: user).lock(true)
      self.number = (Issue.where(user: user).maximum(:number) || 0) + 1
    end
  end
end
