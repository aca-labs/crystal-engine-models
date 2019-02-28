require "uri"

class Engine::Models::Module < Engine::Model
  table :mod

  # The classes / files that this module requires to execute
  # Defines module type
  # Requires dependency_id to be set
  belongs_to Dependency
  belongs_to ControlSystem

  # Device module
  def hostname
    @ip
  end

  def hostname=(host)
    @ip = host
  end

  attribute ip : String
  attribute tls : Bool
  attribute udp : Bool
  attribute port : Int32
  attribute makebreak : Bool = false

  # HTTP Service module
  attribute uri : String

  # Custom module names (in addition to what is defined in the dependency)
  attribute custom_name : String
  attribute settings : String = "{}"

  attribute updated_at : Time = ->{ Time.now }
  attribute created_at : Time = ->{ Time.now }

  attribute role : Dependency::Role # cache the dependency role locally for load order

  # Connected state in model so we can filter and search on it
  attribute connected : Bool = true
  attribute running : Bool = false
  attribute notes : String

  # Don't include this module in statistics or disconnected searches
  # Might be a device that commonly goes offline (like a PC or Display that only supports Wake on Lan)
  attribute ignore_connected : Bool = false
  attribute ignore_startstop : Bool = false

  # helper method for looking up the manager
  # def manager
  #   Control.instance.loaded? self.id
  # end

  # # Returns the node currently running this module
  # def node
  #   # NOTE:: Same function in control_system.cr
  #   @node_id ||= self.edge_id.to_sym
  #   Control.instance.nodes[@node_id]
  # end

  # Loads all the modules for this node in ascending order by default
  #  (device, service then logic)
  # view :all, emit_key: :role

  # # Finds all the modules belonging to a particular dependency
  # index_view :dependency_id, find_method: :dependent_on
  # index_view :edge_id,       find_method: :on_node

  # The systems this module is in use
  def systems
    ControlSystem.by_mod_id(self.id)
  end

  def hostname
    case dependency.role
    when SSH, Device
      self.ip
    when Service
      URI.parse(self.uri).host
    end
  end

  validates :dependency, presence: true
  # validates :edge_id, presence: true

  validate("configuration", ->(this : Module) {
    dependency = this.dependency
    return false if dependency.nil?

    case dependency.role
    when Dependency::Role::SSH
      this.role = Dependency::Role::SSH
      this.port = (this.port || dependency.default || 0).to_i

      # this.errors << ActiveModel.new(this, :ip, "cannot be blank") if this.ip.blank?
      # this.errors << ActiveModel.new(this, :port, "is invalid") unless this.port.between?(1, 65535)
      this.tls = false if this.udp
      url = URI.parse("http://#{this.ip}:#{this.port}/")
      url_parsed = !!(url.scheme && url.host)
      # this.errors << ActiveModel.new(this, :ip, "address / hostname or port are not valid") unless url_parsed
      url_parsed
    when Dependency::Role::Device
      this.role = Dependency::Role::Device
      this.port = (this.port || dependency.default || 0).to_i

      # errors << ActiveModel::Error.new(self, :ip, "cannot be blank") if this.ip.blank?
      # errors << ActiveModel::Error.new(self, :port, "is invalid") unless this.port.between?(1, 65535)

      this.tls = false if this.udp

      url = URI.parse("http://#{this.ip}:#{this.port}/")
      url_parsed = !!(url.scheme && url.host)
      # errors << ActiveModel::Error.new(this, :ip, "address / hostname or port are not valid") unless url_parsed
      url_parsed
    when Dependency::Role::Service
      this.role = Dependency::Role::Service
      this.udp = false

      default = dependency.default
      this.uri ||= default if !default.nil? && default.is_a? String

      uri = this.uri # URI presence
      unless uri
        # errors << ActiveModel.new(this, :uri, "not present")
        return false
      end

      url = URI.parse(uri)
      this.tls = url.scheme == "https" # secure indication

      url_parsed = !!(url.host && url.scheme) # ensure this can be parsed
      # errors << ActiveModel.new(this, :uri, "is an invalid URI") unless url_parsed
      url_parsed
    when Dependency::Role::Logic
      this.connected = true # it is connectionless
      this.tls = nil
      this.udp = nil
      this.role = Dependency::Role::Logic
      has_control = !this.control_system.nil?
      # this.errors << ActiveModel.new(this, :control_system, "must be associated") unless has_control
      has_control
    else
      false # impossible!
    end
  })

  # before_destroy :unload_module

  # protected def unload_module
  #   Control.instance.unload(self.id)

  #   # Find all the systems with this module ID and remove it
  #   self.systems.each do |cs|
  #     cs.modules.delete(self.id)
  #     cs.version += 1
  #     cs.save!
  #   end
  # end
end
