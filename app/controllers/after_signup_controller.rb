class AfterSignupController < ApplicationController
  include Wicked::Wizard
  skip_before_action :require_setup_complete!

  steps :name, :feeds, :delivery

  def show
    @user = current_user
    case step
    when :name
      @zine_preference = @user.zine_preference || @user.build_zine_preference
    when :feeds
      @feeds = Feed.order(:name)
    end
    render_wizard
  end

  def update
    @user = current_user
    case step
    when :name
      @zine_preference = @user.zine_preference || @user.build_zine_preference
      @zine_preference.zine_name = params[:zine_name]
      if @zine_preference.save
        redirect_to wizard_path(:feeds)
      else
        render_wizard
      end
    when :feeds
      @user.feed_ids = Array(params[:feed_ids])
      redirect_to wizard_path(:delivery)
    when :delivery
      pref = @user.zine_preference || @user.create_zine_preference
      pref.update(delivery_day: params[:delivery_day])
      redirect_to after_signup_complete_path
    end
  end

  def complete
    @user = current_user
  end
end
