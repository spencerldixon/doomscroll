class AfterSignupController < ApplicationController
  include Wicked::Wizard

  skip_before_action :require_setup_complete!

  steps :name, :feeds, :delivery

  def show
    case step
    when :name
      @zine_preference = current_user.zine_preference || current_user.build_zine_preference
    when :feeds
      @feeds = Feed.order(:name)
      @user_feed_ids = current_user.feed_ids
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
        render_wizard
      end
    when :feeds
      current_user.feed_ids = Array(params[:feed_ids])

      redirect_to wizard_path(:delivery)
    when :delivery
      pref = current_user.zine_preference || current_user.create_zine_preference
      pref.update(delivery_day: params[:delivery_day])

      redirect_to after_signup_complete_path
    end
  end

  def complete
  end
end
