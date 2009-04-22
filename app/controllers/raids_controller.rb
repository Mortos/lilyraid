class RaidsController < ApplicationController
  before_filter(:load_raid, :only => [:edit, :update, :destroy, :show, :finalize])

  def index
    @old = params[:old]

    if @old
      @raids = Raid.find(:all,
                         :conditions => ["raids.date < ?", Time.now - 5.hours],
                         :order => "raids.date desc")
    else
      @raids = Raid.find(:all,
                         :conditions => ["raids.date >= ?", Time.now - 5.hours],
                         :order => "raids.date")
    end
  end

  def show
    if @raid.uses_loot_system
      @list = List.first
    end
  end

  def finalize
    if @current_account == @raid.account or @current_account.admin
      @raid.finalized = !@raid.finalized
      @raid.save
    end

    respond_to do |format|
      format.html { redirect_to raid_url(@raid) }
    end
  end

  def edit
    if @current_account == @raid.account or @current_account.admin
      @roles = Role.find(:all)
      @cclasses = Cclass.find(:all)
      
      respond_to do |format|
        format.html
      end
    else
      flash[:error] = "You are not authorized to edit this account"
      respond_to do |format|
        format.html { redirect_to raid_url(@raid) }
      end
    end
  end

  def update
    if @current_account.can_edit(@raid)
      @raid.update_attributes(params[:raid])
      @raid.date = Time.parse("#{params[:caldate]} #{params[:caltime]}")
      @raid.save

      # Update Slots

      Slot.update(params[:slot].keys, params[:slot].values)

      respond_to do |format|
        format.html { redirect_to raid_url(@raid) }
      end
    end
  end


  def destroy
    if @current_account.can_edit(@raid)
      @raid.destroy

      respond_to do |format|
        format.html { redirect_to raids_url }
        format.js
      end
    else
      flash[:error] = "You don't have permission to delete that raid"
      respond_to do |format|
        format.html { redirect_to raids_url }
        format.js { redirect_to raids_url }
      end
    end        
  end

  def instance_levels
    instance = Instance.find(params[:id])
    
    render :update do |page|
      page[:raid_min_level].value = instance.min_level
      page[:raid_max_level].value = instance.max_level
      page[:level_loading].replace_html ""
    end
  end

  def new
    @raid = Raid.new
    @raid.date = Date.tomorrow + 18.hours unless @raid.date
  end

  def create
    # Create raid object
    @raid = Raid.new(params[:raid])
    @raid.account = @current_account
    @raid.date = Time.parse("#{params[:caldate]} #{params[:caltime]}")

    if @raid.save
      flash[:notice] = 'Raid saved!'
      redirect_to raid_url(@raid)
    else
      @instances = Instance.find(:all, :order => "name")
      @raid_templates = RaidTemplate.find(:all)
      render :action => 'new'
    end
  end

  private

  def load_raid
    @raid = Raid.find(params[:id])
  end
end

