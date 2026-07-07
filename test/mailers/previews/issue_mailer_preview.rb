class IssueMailerPreview < ActionMailer::Preview
  def daily_issue
    IssueMailer.with(issue: preview_issue).daily_issue
  end

  private

  def preview_issue
    user = User.find_or_create_by!(email: "preview@example.com") do |record|
      record.password = "password123"
      record.password_confirmation = "password123"
      record.terms_and_conditions = true
      record.skip_confirmation!
    end

    user.create_zine_preference!(zine_name: "Preview Zine", delivery_day: Date.current.wday) unless user.zine_preference

    issue = user.issues.order(created_at: :desc).first || user.issues.create!(content: sample_content)
    issue.update!(content: sample_content, title: "Preview Zine", published_at: Time.current)
    issue
  end

  def sample_content
    [
      {
        title: "The Case for Smaller Feeds",
        body: "<p>A focused reader gives you room to notice what is actually worth keeping. This preview article has enough words to make the email stats feel like a real issue.</p>",
        url: "https://example.com/smaller-feeds",
        icon_url: "https://www.google.com/s2/favicons?domain=readwise.io&sz=32",
        source: "Interface Notes",
        author: "Mara Vale",
        published_at: Time.current.iso8601
      },
      {
        title: "Print Is a Better Save Button",
        body: "<p>Printing turns an endless queue into a physical commitment. The point is not nostalgia; it is a cleaner boundary around attention and time.</p>",
        url: "https://example.com/print-save-button",
        icon_url: "https://www.google.com/s2/favicons?domain=paper.li&sz=32",
        source: "Paper Systems",
        author: "Jon Bell",
        published_at: Time.current.iso8601
      },
      {
        title: "A Quiet Web for Sunday Morning",
        body: "<p>The best links often work better in a chair than in a tab. This sample gives the preview email a third article with a source and author.</p>",
        url: "https://example.com/quiet-web",
        icon_url: "https://www.google.com/s2/favicons?domain=thebrowser.com&sz=32",
        source: "Offline Weekly",
        author: "Leah Stone",
        published_at: Time.current.iso8601
      }
    ]
  end
end
