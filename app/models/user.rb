class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable, :confirmable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_one  :zine_preference, dependent: :destroy
  has_many :user_feeds, dependent: :destroy
  has_many :feeds, through: :user_feeds
  has_many :issues, dependent: :destroy

  attr_accessor :terms_and_conditions

  validates_acceptance_of :terms_and_conditions, allow_nil: false, on: :create
  validates :email, presence: true, 'valid_email_2/email': true

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.image = auth.info.image
      user.terms_and_conditions = true
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end

  def setup_complete?
    zine_preference&.zine_name.present? && zine_preference&.delivery_day.present? && user_feeds.any?
  end

  def next_issue_day
    Date::DAYNAMES[zine_preference&.delivery_day]
  end

  def days_until_next_issue
    return nil unless zine_preference.delivery_day

    days_until = (zine_preference.delivery_day - Date.today.wday) % 7

    days_until == 0 ? 7 : days_until
  end

  def next_issue_date
    Date.today + days_until_next_issue
  end
end
