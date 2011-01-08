class ListPosition < ActiveRecord::Base
  belongs_to :account
  belongs_to :list

  default_scope order('position')

  scope :in_raid, lambda do |raid|
    includes(:account => {:characters => :signups}).where('signups.raid_id' => raid.id)
  end

  scope :for_account, lambda do |account|
    where(:account_id => account)
  end

  scope :seated_in, lambda do |raid|
    includes(:account => {:characters => {:signups => :slot}})
      .where('signups.raid_id = ? and slots.id is not null', raid.id)
  end

  def after_destroy
    new_position = self.position

    self.list.list_positions.where('position > ?', self.position).all.each do |lp|
      temp = lp.position
      lp.position = new_position
      lp.save
      new_position = temp
    end
  end
end
