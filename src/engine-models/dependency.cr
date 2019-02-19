require "rethinkdb-orm"
require "set"

class Engine::Dependency < RethinkORM::Base
  after_save :update_modules
  before_destroy :cleanup_modules

  ROLES = Set.new([:ssh, :device, :service, :logic])

  attribute name : String
  attribute role : String
  attribute description : String
  attribute default : String | Int32 # default data (Port or URI)

  # Override default role accessors

  def role
    @role ||= self[:role].to_sym
  end

  def role=(name)
    @role = name.to_sym
    self[:role] = name
  end

  attribute class_name : String
  attribute module_name : String
  attribute settings : Hash(String, String), default: {} of String => String
  attribute created_at : Int64, default: ->{ Time.now }

  # Don't include this module in statistics or disconnected searches
  # Might be a device that commonly goes offline (like a PC or Display that only supports Wake on Lan)
  attribute ignore_connected : Boolean, default: false

  # Find the modules that rely on this dependency
  def modules
    Module.dependent_on(self.id)
  end

  def default_port=(port)
    self.role = :device
    self.default = port
  end

  def default_uri=(uri)
    self.role = :service
    self.default = uri
  end

  # Validations
  validates :name, presence: true
  validates :class_name, presence: true
  validates :module_name, presence: true
  validate :role_exists

  protected def role_exists
    if self.role && ROLES.include?(self.role.to_sym)
      self.role = self.role.to_s
    else
      errors.add(:role, "is not valid")
    end
  end

  # Delete all the module references relying on this dependency
  protected def cleanup_modules
    modules.each do |mod|
      mod.destroy!
    end
  end

  # Reload all modules to update their settings
  protected def update_modules
    ctrl = Control.instance
    return unless ctrl.ready

    dep = self
    mod_found = false

    modules.stream do |mod|
      mod_found = true
      mod.dependency = dep # Otherwise this will hit the database again
      manager = ctrl.loaded? mod.id
      manager.reloaded(mod)
    end
    ctrl.clear_cache if mod_found
  end
end
