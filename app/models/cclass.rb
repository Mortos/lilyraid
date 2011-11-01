class Cclass < ActiveRecord::Base
  has_many :cclass_roles, :dependent => :destroy
  has_many :roles, :through => :cclass_roles

  has_many :slots, :dependent => :nullify

  validates_format_of(:color,
                      :with => /[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/,
                      :message => "must be a valid hex color (#xxxxxx)")

  default_scope order('name')

  def self.named(name)
    self.first(:conditions => { :name => name })
  end

  # Sort by name by default
  def <=>(o)
    self.name <=> o.name
  end
end
