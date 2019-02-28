class Engine::Models::Dependency < Engine::Model
  table :dep

  after_save :update_modules
  before_destroy :cleanup_modules

  enum Role
    SSH
    Device
    Service
    Logic
  end

  attribute name : String
  attribute role : Role
  attribute description : String
  attribute default : String | Int32 # default data (Port or URI)

  attribute class_name : String
  attribute module_name : String
  attribute settings : String = "{}"
  attribute created_at : Time = ->{ Time.now }

  # Don't include this module in statistics or disconnected searches
  # Might be a device that commonly goes offline (like a PC or Display that only supports Wake on Lan)
  attribute ignore_connected : Bool = false

  # Find the modules that rely on this dependency
  def modules
    Module.by_dep_id(self.id)
  end

  def default_port=(port)
    self.role = Role::Device
    self.default = port
  end

  def default_uri=(uri)
    self.role = Role::Service
    self.default = uri
  end

  # Validations
  validates :name, presence: true
  validates :class_name, presence: true
  validates :module_name, presence: true
  validates :role, presence: true

  # Delete all the module references relying on this dependency
  #
  protected def cleanup_modules
    modules.each do |mod|
      mod.destroy!
    end
  end

  # Reload all modules to update their settings
  #
  protected def update_modules
    modules.each do |mod|
      mod.dependency = self # Otherwise this will hit the database again
    end
  end
end
