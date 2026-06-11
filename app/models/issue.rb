class Issue < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :number, presence: true, uniqueness: { scope: :user_id }
  validates :published_at, presence: true

  before_validation :set_content, on: :create
  before_validation :set_issue_title,  on: :create
  before_validation :set_issue_number, on: :create
  before_validation :set_published_at, on: :create

  private

  def set_content
    return unless user
    return if content.present?

    self.content = ContentGenerator.new(user: user).generate.to_json
  end

  def set_issue_title
    self.title = user.zine_preference&.zine_name || "Doomscroll"
  end

  def set_issue_number
    Issue.transaction do
      Issue.where(user: user).lock(true)
      self.number = (Issue.where(user: user).maximum(:number) || 0) + 1
    end
  end

  def set_published_at
    self.published_at = DateTime.current
  end
end
