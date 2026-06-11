require "set"

module IssuesHelper
  WORD_STAT_STOP_WORDS = %w[
    the and for that with from this you are was were have has had but not they
    its his her she him them their your our can will would could should there
    about into than then when where what who why how all any one two out over
    under more most less least just also because while after before been being
    article source
  ].to_set.freeze

  def issue_article_word_stats(articles)
    words = article_words(articles)
    frequency_words = words.reject { |word| WORD_STAT_STOP_WORDS.include?(word) }
    frequencies = frequency_words.tally

    {
      word_count: words.size,
      most_used_word: frequencies.max_by { |word, count| [ count, word ] }&.first,
      least_used_word: frequencies.min_by { |word, count| [ count, word ] }&.first
    }
  end

  private

  def article_words(articles)
    Array(articles).flat_map do |article|
      article = article.with_indifferent_access
      nested_article = article[:article].presence&.with_indifferent_access || {}
      body = article[:body].presence || article[:content].presence || article[:body_chunk].presence || nested_article[:body].presence || ""

      strip_tags(body).downcase.scan(/[[:alpha:]][[:alpha:]']+/)
    end
  end
end
