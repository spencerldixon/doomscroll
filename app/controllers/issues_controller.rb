class IssuesController < ApplicationController
  before_action :authenticate_user!
  layout "issue", only: :show

  def index
    @issues = current_user.issues.order(number: :desc)
  end

  def show
    @issue = current_user.issues.find(params[:id])
  end
end
