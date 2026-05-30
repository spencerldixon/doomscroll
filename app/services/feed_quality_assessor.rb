require "ssrf_filter"

class FeedQualityAssessor
  TRUNCATION_PATTERNS = [
    /read (more|on)/i,
    /continue reading/i,
    /full (story|article|post)/i,
    /click here (to read|for more)/i,
    /keep reading/i,
    /more »/i,
    /\[[\.…]+\]/,
  ].freeze

  FULL_TEXT_MIN_CHARS = 400
  SAMPLE_SIZE = 10 

  Result = Data.define(:quality, :sample_size, :avg_chars)

  def initialize(url)
    @url = url
    @feed = fetch_feed
    @posts = parsed_posts
  end

  # Returns a Result with quality: :full | :partial | :empty | :unknown
  def rate_quality
    return Result.new(quality: :unknown, sample_size: 0, avg_chars: 0) if @posts.empty?

    sample = @posts.first(SAMPLE_SIZE).map { score(_1) }

    avg_chars     = sample.sum { _1[:chars] } / sample.size
    empty_ratio   = sample.count { _1[:empty] }.to_f   / sample.size
    partial_ratio = sample.count { _1[:partial] }.to_f / sample.size

    quality = if empty_ratio >= 0.6
      :empty
    elsif partial_ratio >= 0.4 || avg_chars < FULL_TEXT_MIN_CHARS
      :partial
    else
      :full
    end

    Result.new(quality: quality, sample_size: sample.size, avg_chars: avg_chars)
  end

  private

  def score(item)
    raw     = best_content(item)
    text    = strip_html(raw)
    chars   = text.length
    signals = TRUNCATION_PATTERNS.any? { raw.match?(_1) }

    { chars: chars, empty: chars < 50, partial: signals || chars < FULL_TEXT_MIN_CHARS }
  end

  def best_content(item)
    item.at_xpath("encoded")&.text ||
      item.at_xpath("description")&.text ||
      item.at_xpath("content")&.text ||
      item.at_xpath("summary")&.text ||
      ""
  end

  def strip_html(html)
    Nokogiri::HTML(html).text.gsub(/\s+/, " ").strip
  end

  def parsed_posts
    return [] unless @feed

    doc = Nokogiri::XML(@feed)
    doc.remove_namespaces!

    posts = doc.xpath("//item")
    posts = doc.xpath("//entry") if posts.empty?
    posts
  end

  def fetch_feed
    SsrfFilter.get(@url, headers: { "User-Agent" => "Doomscroll/1.0" }).body
  end
end
