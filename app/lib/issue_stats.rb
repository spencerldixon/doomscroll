class IssueStats
  READING_WORDS_PER_MINUTE = 220

  # Rough phone-reading model behind "scroll distance saved": ~5 words per
  # line, ~0.6cm of screen height per line.
  SCROLL_CM_PER_WORD = 0.12

  MIN_INTERESTING_WORD_LENGTH = 4

  STOPWORDS = %w[
    the a an and or but if then than that this these those there their they
    them then when what which while where because about into over after
    before more most other some such only just also very much many each
    been being have has had does did done will would can could should shall
    is are was were be it its with as in on at to for from by of not no so
    do you your yours our ours his her hers him she he we us me my mine i
    like even still well said says say make made get got how who whom whose
    out off up down too here now new one two first last between through
    during under above both any all
  ].to_set.freeze

  def initialize(articles)
    @articles = articles
  end

  def word_count
    words.size
  end

  def reading_minutes
    (word_count / READING_WORDS_PER_MINUTE.to_f).ceil
  end

  def scroll_meters
    (word_count * SCROLL_CM_PER_WORD / 100).round(1)
  end

  def source_count
    @articles.map { |article| article["source"] }.uniq.size
  end

  def most_used_word
    word, _count = frequencies.max_by { |_word, count| count }
    word
  end

  # The longest word that appears exactly once in the issue.
  def rarest_word
    frequencies.select { |_word, count| count == 1 }.keys.max_by(&:length)
  end

  private

  def words
    @words ||= @articles
      .map { |article| ActionView::Base.full_sanitizer.sanitize(article["body"].to_s) }
      .join(" ")
      .downcase
      .scan(/[a-z][a-z'-]+/)
  end

  def frequencies
    @frequencies ||= words
      .reject { |word| word.length < MIN_INTERESTING_WORD_LENGTH || STOPWORDS.include?(word) }
      .tally
  end
end
