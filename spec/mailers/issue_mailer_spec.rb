require "rails_helper"

RSpec.describe IssueMailer, type: :mailer do
  describe "#daily_issue" do
    it "emails the user a signed print link for the issue" do
      user = User.create!(
        email: "reader@example.com",
        password: "password123",
        password_confirmation: "password123",
        terms_and_conditions: true,
        confirmed_at: Time.current
      )
      user.create_zine_preference!(zine_name: "Reader Weekly", delivery_day: Date.current.wday)
      issue = user.issues.create!(
        content: [
          {
            title: "A Useful Article",
            body: "<p>This article has enough words to produce useful stats for a preview of the issue email.</p>",
            source: "Example Source",
            author: "Alex Reader",
            url: "https://example.com/a-useful-article",
            icon_url: "https://www.google.com/s2/favicons?domain=example.com&sz=32",
            published_at: Time.current.iso8601
          }
        ]
      )

      mail = described_class.with(issue: issue).daily_issue

      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq("Your Reader Weekly issue ##{issue.number} is off the press")
      expect(mail.body.encoded).to include("doomscroll.press")
      expect(mail.body.encoded).to include("Your new issue is ready to print")
      expect(mail.body.encoded).to include("Print your issue")
      expect(mail.body.encoded).to include("DOOMSCROLL.PRESS")
      expect(mail.body.encoded).to include("<svg")
      expect(mail.body.encoded).to include("https://www.google.com/s2/favicons?domain=example.com&amp;sz=32")
      expect(mail.body.encoded).to include("Issue stats")
      expect(mail.body.encoded).to include("A Useful Article")
      expect(mail.body.encoded).to include("Alex Reader")
      expect(mail.body.encoded).to include("Print instructions")
      expect(mail.body.encoded).to include("/issues/#{issue.id}?token=")
    end
  end
end
