class Raid < ActiveRecord::Base
  belongs_to :account

  belongs_to :instance

  has_many :raider_tags
  has_many :tags, :through => :raider_tags

  has_many :locations
  accepts_nested_attributes_for(:locations, :allow_destroy => true,
                                :reject_if => proc { |attr|
                                  attr['instance_id'].blank?
                                })
  has_many :instances, :through => :locations
  has_many :loots, :through => :locations

  belongs_to :raid_template

  has_many :slots, :dependent => :destroy
  accepts_nested_attributes_for(:slots,
                                :allow_destroy => true)

  has_many :signups, :dependent => :destroy
  has_many :characters, :through => :signups

  has_many :logs

  scope :past, lambda { where('raids.date < ?', Date.today) }
  scope :last_month, lambda { where('raids.date >= ?', Date.today - 1.month) }
  scope :last_three_months, lambda { where('raids.date >= ?', Date.today - 3.months) }
  scope :in_instance, lambda { |instance| where(:instance_id => instance) }

  # Validation
  validates_presence_of :name

  def started?
    Time.now > self.date
  end

  def needed
    slots.empty.count(:include => :role, :group => "roles.name")
  end

  def confirmed_characters
    slots.map do |slot|
      if slot.signup
        slot.signup.character
      end
    end.compact
  end

  def accounts
    slots.map do |slot|
      if slot.signup
        slot.signup.character.account
      end
    end.compact
  end

  def character_in_raid(character)
    confirmed_characters.member?(character)
  end

  def waiting_list_by_account
    waiting_list.inject([]) do |list, signup|
      if list.empty?
        [[signup]]
      elsif list.last.first.character.account_id == signup.character.account_id
        list.last << signup
        list
      else
        list << [signup]
      end
    end
  end

  def is_open
    return true

    slots.each do |slot|
      if !slot.closed
        return true
      end
    end

    return false
  end

  def signups_from(account)
    signups.select do |signup|
      signup.character.account == account
    end
  end

  def remove_character(char)
    # Delete the signup_slot_types and signup row
    signup = self.signups.where(:character_id => char).first

    if signup
      date = signup.date
      # Destroy signups, this opens the slots up as well
      Signup.destroy(signup.id)

      # Redo the raid if raid
      resignup(date) unless locked

      return true
    else
      return false
    end
  end

  def find_character(char)
    self.slots.includes(:signup).where(:character_id => char).first
  end

  def resignup(date)
    signups = Signup.where('date >= ?', date).all

    # Delete all slots that are tied to signsup past this date
    signups.each do |signup|
      signup.clear_slots
    end

    # redo all signups that occur on or past this date
    signups.each do |signup|
      place_character(signup)
    end
  end

  def waiting_list
    accounts = slots.map { |slot| slot.signup }.compact.map { |signup| signup.character.account }

    signups.select do |signup|
      !accounts.member?(signup.character.account)
    end
  end

  def place_character(signup)
    self.slots.where('signup_id is null and closed = ?', false).order('cclass_id desc, slot_type_id desc').all.each do |slot|
      if slot.accept_char(signup)
        # This slow will accept this character
        slot.signup = signup
        slot.save
        break;
      end
    end
  end

  def add_waiting_list
    waiting_list.each do |signup|
      place_character(signup)
    end
  end

  def groups
    slots.each_slice(5)
  end

  def can_be_deleted?
    loots.size == 0
  end

  # Used for templates
  def template_id=(template_id)
    return if template_id.blank?

    # Number of slots that this raid has
    number_in_raid = self.slots.count

    # Apply a raid template to this raid
    template = Template.find(template_id)
    number_in_template = template.slots.count

    # Remove some slots from this raid
    self.slots.all[number_in_template..-1].map(&:destroy) if number_in_template < number_in_raid

    template.slots.each_with_index do |slot, index|
      if index < number_in_raid
        raid_slot = self.slots[index]

        # We only care if these slots are different
        if raid_slot != slot
          signup = raid_slot.signup
          raid_slot.update_attributes(slot.attributes)
          raid_slot.raid = self
          raid_slot.template = nil

          # Remove character if there is one that doesn't fit into the template
          if signup and raid_slot.accept(signup)
            raid_slot.signup = signup
          end
        end
      else
        # Easy, just create the new one
        self.slots.build(slot.attributes).template = nil
      end
    end
  end

  def template_id
    nil
  end

  def uid
    "raid_#{self.id}@raids.dota-guild.com"
  end

  def caldate
    date.strftime("%m/%d/%Y")
  end

  def caltime
    date.strftime("%I:%M %p")
  end
end
