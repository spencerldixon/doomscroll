class DailyIssueGeneratorJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    date = date.to_date

    due_users(date).find_each do |user|
      next if issue_already_created?(user, date)

      issue = user.issues.create!
      IssueMailer.with(issue: issue).daily_issue.deliver_later
    rescue StandardError => e
      Rails.logger.error("DailyIssueGeneratorJob failed for user #{user.id}: #{e.class} #{e.message}")
    end
  end

  private

  def due_users(date)
    User
      .joins(:zine_preference)
      .where(zine_preferences: { delivery_day: date.wday })
      .where.associated(:user_feeds)
      .distinct
  end

  def issue_already_created?(user, date)
    user.issues.where(published_at: date.all_day).exists?
  end
end
