class OnboardingController < ApplicationController
  include Wicked::Wizard

  skip_before_action :require_setup_complete!

  MINIMUM_FEEDS = 3

  steps :name, :feeds, :delivery

  def show
    case step
    when :name
      @zine_preference = current_user.zine_preference || current_user.build_zine_preference
    when :feeds
      @feeds = Feed.where(public: true).order(:name)
      @categories = @feeds.map(&:category).compact.uniq.sort
      @user_feed_ids = current_user.feed_ids
    when :delivery
      @zine_preference = current_user.zine_preference || current_user.build_zine_preference
    end

    render_wizard
  end

  def update
    case step
    when :name
      @zine_preference = current_user.zine_preference || current_user.build_zine_preference
      @zine_preference.zine_name = params[:zine_name]

      if @zine_preference.save
        redirect_to wizard_path(:feeds)
      else
        flash.now[:alert] = "Please name your zine"
        render_wizard nil, status: :unprocessable_entity
      end
    when :feeds
      feed_ids = Array(params[:feed_ids]).reject(&:blank?)

      if feed_ids.size >= MINIMUM_FEEDS
        current_user.feed_ids = feed_ids
        redirect_to wizard_path(:delivery)
      else
        flash.now[:alert] = "Please select at least #{MINIMUM_FEEDS} feeds"
        @feeds = Feed.where(public: true).order(:name)
        @categories = @feeds.map(&:category).compact.uniq.sort
        @user_feed_ids = feed_ids.map(&:to_i)
        render_wizard nil, status: :unprocessable_entity
      end
    when :delivery
      @zine_preference = current_user.zine_preference || current_user.build_zine_preference
      @zine_preference.delivery_day = params[:delivery_day]
      @zine_preference.delivery_frequency = params[:delivery_frequency]

      if @zine_preference.delivery_day.present? && @zine_preference.delivery_frequency.present? && @zine_preference.save
        redirect_to onboarding_complete_path
      else
        flash.now[:alert] = "Please pick a delivery day and schedule"
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end

  def complete
  end
end
