class DailyIssueGeneratorJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    date = date.to_date

    due_preferences(date).find_each do |preference|
      next unless preference.due_on?(date)

      user = preference.user
      next if issue_already_created?(user, date)

      issue = nil
      ZinePreference.transaction do
        issue = user.issues.create!
        preference.update!(last_delivered_on: date)
      end

      IssueMailer.with(issue: issue).daily_issue.deliver_later
    rescue StandardError => e
      Rails.logger.error("DailyIssueGeneratorJob failed for user #{preference.user_id}: #{e.class} #{e.message}")
    end
  end

  private

  def due_preferences(date)
    ZinePreference
      .where(delivery_day: date.wday)
      .where(user_id: UserFeed.select(:user_id))
      .includes(:user)
  end

  def issue_already_created?(user, date)
    user.issues.where(published_at: date.all_day).exists?
  end
end
