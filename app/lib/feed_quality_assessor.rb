class FeedQualityAssessor
  TRUNCATION_PATTERNS = [
    /read (more|on)/i,
    /continue reading/i,
    /full (story|article|post)/i,
    /click here (to read|for more)/i,
    /keep reading/i,
    /more »/i,
    /\[[\.…]+\]/
  ].freeze

  FULL_TEXT_MIN_CHARS = 500
  SAMPLE_SIZE = 10

  Result = Data.define(:quality, :sample_size, :avg_chars)

  def initialize(feed)
    @posts = feed.items
  end

  def rate
    # Returns a Result with a quality of either: [:full, :partial, :empty, :unknown]
    return :unknown if @posts.empty?

    sample_posts = @posts.first(SAMPLE_SIZE).map { |post| score_post(post) }

    avg_chars     = sample_posts.sum { _1[:chars] } / sample_posts.size
    empty_ratio   = sample_posts.count { _1[:empty] }.to_f   / sample_posts.size
    partial_ratio = sample_posts.count { _1[:partial] }.to_f / sample_posts.size

    quality = if empty_ratio >= 0.6
      :empty
    elsif partial_ratio >= 0.4 || avg_chars < FULL_TEXT_MIN_CHARS
      :partial
    else
      :full
    end

    quality
  end

  private

  def score_post(item)
    # Takes a single blog post item and returns score metrics
    content         = item.content_text
    content_length  = content.length
    truncated       = TRUNCATION_PATTERNS.any? { content.match?(_1) }

    {
      chars: content_length,
      empty: content_length < 50,
      partial: truncated || content_length < FULL_TEXT_MIN_CHARS
    }
  end
end
