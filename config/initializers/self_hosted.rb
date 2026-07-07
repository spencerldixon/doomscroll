Rails.configuration.x.self_hosted = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("SELF_HOSTED")
)
