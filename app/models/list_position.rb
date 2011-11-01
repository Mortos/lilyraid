class ListPosition < ActiveRecord::Base
  belongs_to :account
  belongs_to :list

  default_scope :order => "position"

  scope :in_raid, lambda { |raid| {
      :include => { :account => { :characters => :signups } },
      :conditions => ["signups.raid_id = ?", raid.id] } }

  scope :for_account, lambda { |account| {
      :conditions => { :account_id => account } } }

  scope :seated_in, lambda { |raid| {
      :include => { :account => { :characters => { :signups => :slot } } },
      :conditions => ["signups.raid_id = ? and slots.id is not null", raid.id] } }

  def after_destroy
    new_position = self.position

    self.list.list_positions.find(:all,
                                  :order => :position,
                                  :conditions => ["position > ?",
                                                  self.position]).each do |lp|
      temp = lp.position
      lp.position = new_position
      lp.save
      new_position = temp
    end
  end
end
