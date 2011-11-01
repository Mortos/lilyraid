# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '599f44b29c4a78b118884b977571fb10'

  if Rails.env == 'development'
    before_filter :fake_authorize
  else
    before_filter :authorize
  end

  private

  def finalize_log(raid)
    Log.create(:source => raid.finalized ? 'finalized' : 'unfinalized',
               :account_id => @current_account.id,
               :raid_id => raid.id)
  end

  def signup_log(signup, message)
    Log.create(:source => 'signup',
               :account_id => @current_account.id,
               :raid_id => signup.raid.id,
               :character_id => signup.character.id,
               :message => message)
  end

  def slot_log(raid, character, message)
    Log.create(:source => 'slot',
               :account_id => @current_account.id,
               :raid_id => raid.id,
               :character_id => character.id,
               :message => message)
  end

  def loot_log(loot, message)
    Log.create(:source => 'loot',
               :account_id => @current_account.id,
               :raid_id => loot.raid.id,
               :character_id => loot.character.id,
               :loot_id => loot.id,
               :message => message)
  end

  def fake_authorize
    session[:account_id] = 2
    @current_account = Account.find(2)
  end

  def authorize
    @current_account = Account.find_by_id(session[:account_id])

    redirect_to(:controller => 'login', :action => 'index') unless @current_account
  end

  def require_admin
    # Check if the admin flag is set
    unless @current_account.admin
      flash[:error] = "You do not have permission for this action"
      render raids_url()
      return false
    end
  end

  def display_error(msg)
    render :update do |page|
      page.alert(msg)
      yield page if block_given?
    end
  end
end
