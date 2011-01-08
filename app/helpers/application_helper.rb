module ApplicationHelper
  def admin?
    @current_account.admin?
  end

  def current_account_path
    account_path(@current_account)
  end

  def logged_in?
    !!@current_account
  end
end
