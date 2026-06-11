class IssuesController < ApplicationController
  #before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: :show
  skip_before_action :require_setup_complete!, only: :show
  layout "issue", only: :show

  # Print layout for issue pages: false = reader spreads, true = booklet
  # imposition (fold-and-staple page ordering).
  BOOKLET_PRINT_MODE = true

  def index
    @issues = current_user.issues.order(number: :desc)
  end

  def show
    @issue = current_user.issues.find(params[:id])
    @articles = JSON.parse(@issue.content)
    @stats = IssueStats.new(@articles)
    @booklet_print_mode = BOOKLET_PRINT_MODE
  end
end
