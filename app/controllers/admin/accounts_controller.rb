class Admin::AccountsController < ApplicationController
  before_filter :require_admin

  def index
    @accounts = Account.order('name').all

    @account = Account.new
    @character = Character.new
    @cclasses = Cclass.order('name').all

    @deletable = Account.order('name').all.select do |account|
      account.can_delete?
    end
  end

  def create
    @account = Account.new(params[:account])
    @character = Character.new(params[:character])
    @character.account = @account

    if @account.valid? and @character.valid?
      @account.save
      @character.save
      redirect_to account_url(@account.id)
    else
      @cclasses = Cclass.order('name').all

      @deletable = Account.order('name').all.select do |account|
        account.can_delete?
      end

      render :action => "index"
    end
  end

  def rename
    Account.update(params[:id], params[:account])

    redirect_to admin_accounts_url
  end

  def destroy
    Account.find(params[:id]).destroy

    redirect_to accounts_url
  end
end
