require "rails_helper"

RSpec.describe DailyIssueGeneratorJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear

    travel_to Time.zone.local(2026, 6, 23, 9, 0, 0) do
      example.run
    end
  ensure
    travel_back
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it "creates and emails an issue for users due today" do
    due_user = create_user_with_delivery(email: "due@example.com", delivery_day: Date.current.wday)
    create_user_with_delivery(email: "later@example.com", delivery_day: Date.tomorrow.wday)

    expect {
      perform_enqueued_jobs do
        described_class.perform_now(Date.current)
      end
    }.to change(Issue, :count).by(1)
      .and change(ActionMailer::Base.deliveries, :count).by(1)

    issue = due_user.issues.sole
    email = ActionMailer::Base.deliveries.sole

    expect(issue.published_at.to_date).to eq(Date.current)
    expect(email.to).to eq([due_user.email])
    expect(email.body.encoded).to include("/issues/#{issue.id}?token=")
  end

  it "does not create a duplicate issue for a user who already has one today" do
    due_user = create_user_with_delivery(email: "due@example.com", delivery_day: Date.current.wday)
    due_user.issues.create!(content: [])

    expect {
      perform_enqueued_jobs do
        described_class.perform_now(Date.current)
      end
    }.not_to change(Issue, :count)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  def create_user_with_delivery(email:, delivery_day:)
    user = User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )

    user.create_zine_preference!(zine_name: "Daily Zine", delivery_day: delivery_day)
    feed = Feed.create!(name: "Feed #{email}", url: "https://#{email}/rss.xml")
    user.user_feeds.create!(feed: feed)
    user
  end
end
