class ArticlePaginator
  # Calibrate by rendering a known-length article and measuring what fits.
  CHARS_PER_SLOT = 700
  CAPACITY       = 20  # 10 sheets × 2 halves
  TOLERANCE      = 2   # allow one sheet overflow

  Slot = Data.define(:article, :body_chunk, :slot_number, :first, :last)

  def self.paginate(articles)
    new(articles).slots
  end

  def initialize(articles)
    @articles = articles
  end

  def slots
    result     = []
    slot_index = 0

    @articles.each do |article|
      chunks = chunk(article[:body])

      break if slot_index + chunks.size > CAPACITY + TOLERANCE

      chunks.each_with_index do |chunk, i|
        result << Slot.new(
          article:     article,
          body_chunk:  chunk,
          slot_number: slot_index + i + 1,
          first:       i == 0,
          last:        i == chunks.size - 1
        )
      end

      slot_index += chunks.size
      break if slot_index >= CAPACITY - TOLERANCE
    end

    result
  end

  private

  def chunk(html)
    paragraphs = extract_paragraphs(html)
    chunks, current, current_len = [], [], 0

    paragraphs.each do |para|
      if current_len + para.length > CHARS_PER_SLOT && current.any?
        chunks << current.join("\n\n")
        current, current_len = [], 0
      end
      current << para
      current_len += para.length
    end

    chunks << current.join("\n\n") if current.any?
    chunks.presence || [""]
  end

  def extract_paragraphs(html)
    nodes = Nokogiri::HTML(html).css("p, li, blockquote, h2, h3")
    return html.split(/\n\n+/).map(&:strip).reject(&:empty?) if nodes.empty?

    nodes.map(&:text).map(&:strip).reject(&:empty?)
  end
end
