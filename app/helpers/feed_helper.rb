module FeedHelper
  def feed_icon(feed, size: 32, classes: nil)
    if feed.domain.present?
      url = "https://www.google.com/s2/favicons?domain=#{feed.domain}&sz=#{size}"

      image_tag(url, size: size, alt: feed.name, lazy: true, class: classes)
    else
      content_tag(:div, "", class: classes + " bg-lime-400")
    end
  end

  def feed_icon_url(domain, size: 32, classes: nil)
    url = "https://www.google.com/s2/favicons?domain=#{domain}&sz=#{size}"

    image_tag(url, size: size, alt: url, lazy: true, class: classes)
  end

  def feed_quality_indicator(feed)
    quality = feed.quality.presence || "unknown"
    color_class = {
      "full" => "bg-green-500",
      "partial" => "bg-amber-400",
      "empty" => "bg-red-500",
      "unknown" => "bg-neutral-400"
    }.fetch(quality, "bg-neutral-400")

    label = "Feed Quality Rating: #{quality.humanize.titleize}"

    content_tag(
      :span,
      "",
      class: "inline-block h-1.5 w-1.5 rounded-full #{color_class}",
      title: label,
      aria: { label: label }
    )
  end
end
