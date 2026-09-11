encryption = Rails.application.config.active_record.encryption

if Rails.env.production?
  encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence or raise("Set ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY (see README)")
  encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence or raise("Set ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY (see README)")
  encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence or raise("Set ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT (see README)")
else
  # Fixed, non-secret keys so development and test don't each need their own .env entry.
  encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence || "QvNxsBcKLBDmo46eXkWBPwtSN1i5wtWK"
  encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence || "rz4WDM5kqfsXhEgMl3Po9DGHEhU54aoE"
  encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence || "VH45URpc0s41Awd7wO0455kFIikrJS16"
end
