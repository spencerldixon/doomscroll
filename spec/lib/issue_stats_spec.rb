require "rails_helper"

RSpec.describe IssueStats do
  subject(:stats) { described_class.new(articles) }

  let(:articles) do
    [
      { "source" => "Blog A", "body" => "<p>Quantum computers compute. <strong>Quantum</strong> quantum!</p>" },
      { "source" => "Blog B", "body" => "<p>Unique xylophones exist.</p>" },
      { "source" => "Blog A", "body" => "" }
    ]
  end

  it "counts words across all article bodies, ignoring markup" do
    expect(stats.word_count).to eq(8)
  end

  it "rounds reading time up to a whole minute" do
    expect(stats.reading_minutes).to eq(1)
  end

  it "estimates scroll distance in meters" do
    expect(stats.scroll_meters).to eq((8 * IssueStats::SCROLL_CM_PER_WORD / 100).round(1))
  end

  it "counts distinct sources" do
    expect(stats.source_count).to eq(2)
  end

  it "finds the most used non-stopword" do
    expect(stats.most_used_word).to eq("quantum")
  end

  it "finds the longest word used exactly once" do
    expect(stats.rarest_word).to eq("xylophones")
  end

  context "with no articles" do
    let(:articles) { [] }

    it "returns empty-safe values" do
      expect(stats.word_count).to eq(0)
      expect(stats.reading_minutes).to eq(0)
      expect(stats.scroll_meters).to eq(0.0)
      expect(stats.source_count).to eq(0)
      expect(stats.most_used_word).to be_nil
      expect(stats.rarest_word).to be_nil
    end
  end
end
