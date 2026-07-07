require "rails_helper"
require "tempfile"

RSpec.describe "Feeds", type: :request do
  let(:user) do
    User.create!(
      email: "feeds@example.com",
      password: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )
  end

  let!(:setup_feed) do
    Feed.create!(
      name: "Setup Feed",
      url: "https://setup.example.com/rss.xml",
      domain: "setup.example.com"
    )
  end

  before do
    user.create_zine_preference!(zine_name: "My Zine", delivery_day: 1)
    user.feeds << setup_feed
    sign_in user

    allow(FeedDiscoverJob).to receive(:perform_later)
  end

  describe "GET /feeds" do
    it "renders the feed intake controls" do
      get feeds_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Add feeds")
      expect(response.body).to include("Import OPML")
    end
  end

  describe "POST /feeds/import_opml" do
    it "subscribes the user to existing feeds and creates new feeds from OPML outlines" do
      existing_feed = Feed.create!(
        name: "Existing Feed",
        url: "https://existing.example.com/rss.xml",
        domain: "existing.example.com"
      )

      opml = <<~OPML
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <body>
            <outline text="Existing Feed" xmlUrl="https://existing.example.com/rss.xml" />
            <outline text="New Feed" xmlUrl="https://new.example.com/rss.xml" />
            <outline text="Invalid Feed" xmlUrl="not a url" />
            <outline text="No URL" />
          </body>
        </opml>
      OPML

      expect {
        post import_opml_feeds_path, params: { opml_file: uploaded_opml(opml) }
      }.to change(Feed, :count).by(1)
        .and change(UserFeed, :count).by(2)

      new_feed = Feed.find_by!(url: "https://new.example.com/rss.xml")

      expect(response).to redirect_to(feeds_path)
      expect(flash[:notice]).to eq("Imported 2 feeds. Skipped 1 invalid entry.")
      expect(user.reload.feeds).to include(existing_feed, new_feed)
      expect(new_feed.name).to eq("New Feed")
      expect(new_feed.domain).to eq("new.example.com")
      expect(FeedDiscoverJob).to have_received(:perform_later).with(new_feed)
    end

    it "rejects OPML files without feeds" do
      opml = <<~OPML
        <opml version="2.0">
          <body>
            <outline text="Folder" />
          </body>
        </opml>
      OPML

      post import_opml_feeds_path, params: { opml_file: uploaded_opml(opml) }

      expect(response).to redirect_to(feeds_path)
      expect(flash[:alert]).to eq("No feeds found in that OPML file.")
    end

    it "requires a file upload" do
      post import_opml_feeds_path

      expect(response).to redirect_to(feeds_path)
      expect(flash[:alert]).to eq("Please choose an OPML file to import.")
    end
  end

  def uploaded_opml(content)
    file = Tempfile.new(["feeds", ".opml"])
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/x-opml")
  end
end
