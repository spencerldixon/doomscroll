class IssuesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :require_setup_complete!, only: :show

  layout "issue", only: :show

  # Print layout for issue pages: false = reader spreads, true = booklet
  # imposition (fold-and-staple page ordering).
  BOOKLET_PRINT_MODE = true

  def index
    @issues = current_user.issues.order(number: :desc)
  end

  def show
    @issue = find_issue_for_show
    @articles = JSON.parse(@issue.content)
    @stats = IssueStats.new(@articles)
    @booklet_print_mode = BOOKLET_PRINT_MODE
  end

  private

  def find_issue_for_show
    if params[:token].present?
      issue = Issue.find_signed(params[:token], purpose: :issue_print)
      return issue if issue&.id.to_s == params[:id].to_s
    end

    return current_user.issues.find(params[:id]) if current_user

    raise ActiveRecord::RecordNotFound
  end
end
