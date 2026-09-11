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

      deliver(issue, preference)
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

  def deliver(issue, preference)
    if preference.delivery_method == "telegram"
      deliver_via_telegram(issue, preference)
    else
      IssueMailer.with(issue: issue).daily_issue.deliver_later
    end
  end

  def deliver_via_telegram(issue, preference)
    issue_url = Rails.application.routes.url_helpers.issue_url(
      issue,
      token: issue.signed_id(purpose: :issue_print),
      **Rails.application.config.action_mailer.default_url_options
    )

    TelegramNotifier.notify(
      "<b>#{issue.title}</b> issue ##{issue.number} is off the press.\n#{issue_url}",
      token: preference.telegram_bot_token.presence || ENV["TELEGRAM_BOT_TOKEN"],
      chat_id: preference.telegram_chat_id.presence || ENV["TELEGRAM_CHAT_ID"]
    )
  end
end
