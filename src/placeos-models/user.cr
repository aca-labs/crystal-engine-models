require "CrystalEmail"
require "crypto/bcrypt/password"
require "digest/md5"
require "rethinkdb-orm"

require "./authority"
require "./base/model"

module PlaceOS::Model
  class User < ModelBase
    include RethinkORM::Timestamps
    table :user

    belongs_to Authority

    attribute name : String, es_subfield: "keyword"
    attribute nickname : String = ""
    attribute email : String = ""
    attribute phone : String = ""
    attribute country : String = ""
    attribute image : String = ""
    attribute ui_theme : String = "light"
    attribute misc : String = ""

    attribute login_name : String?, mass_assignment: false
    attribute staff_id : String?, mass_assignment: false
    attribute first_name : String?
    attribute last_name : String?
    attribute building : String?

    attribute password_digest : String?, mass_assignment: false
    attribute email_digest : String?, mass_assignment: false
    attribute card_number : String?, mass_assignment: false

    attribute deleted : Bool = false, mass_assignment: false
    attribute groups : Array(String) = [] of String, mass_assignment: false

    attribute access_token : String?, mass_assignment: false
    attribute refresh_token : String?, mass_assignment: false
    attribute expires_at : Int64?, mass_assignment: false
    attribute expires : Bool = false, mass_assignment: false

    attribute password : String?

    attribute sys_admin : Bool = false, mass_assignment: false
    attribute support : Bool = false, mass_assignment: false

    has_many(
      child_class: UserAuthLookup,
      dependent: :destroy,
      foreign_key: "user_id",
      collection_name: :auth_lookups
    )

    # Metadata belonging to this user
    has_many(
      child_class: Metadata,
      collection_name: "metadata",
      foreign_key: "parent_id",
      dependent: :destroy
    )

    # Validation
    ###############################################################################################

    validates :authority_id, presence: true
    validates :email, presence: true

    validate ->(this : User) {
      this.validation_error(:email, "is an invalid email") unless this.email.is_email?
    }

    # Ensure email is unique under the authority scope
    #
    ensure_unique :email, scope: [:authority_id, :email] do |authority_id, email|
      {authority_id, email.strip.downcase}
    end

    # Callbacks
    ###############################################################################################

    before_destroy :cleanup_auth_tokens
    before_save :build_name
    before_save :create_email_digest

    # deletes auth tokens
    protected def cleanup_auth_tokens
      user_id = self.id

      begin
        ::RethinkORM::Connection.raw do |r|
          r.table("doorkeeper_grant").filter { |grant|
            grant["resource_owner_id"].eq(user_id)
          }.delete
        end
      rescue
        Log.warn { "failed to remove User<#{user_id}> auth grants" }
      end

      begin
        ::RethinkORM::Connection.raw do |r|
          r.table("doorkeeper_token").filter { |token|
            token["resource_owner_id"].eq(user_id)
          }.delete
        end
      rescue
        Log.warn { "failed to remove User<#{user_id}> auth tokens" }
      end
    end

    protected def build_name
      self.name = "#{self.first_name} #{self.last_name}" if self.first_name.presence
    end

    # Sets email_digest to allow user look up without leaking emails
    #
    protected def create_email_digest
      self.email_digest = Digest::MD5.hexdigest(self.email)
    end

    # Indices
    ###############################################################################################

    secondary_index :authority_id

    def by_authority_id(auth_id : String)
      User.get_all([auth_id], index: :authority_id)
    end

    secondary_index :email

    def self.find_by_email(authority_id : String, email : String)
      User.where(email: email, authority_id: authority_id).first?
    end

    secondary_index :login_name

    def self.find_by_login_name(login_name : String)
      User.get_all([login_name], index: :login_name).first?
    end

    secondary_index :staff_id

    def self.find_by_staff_id(staff_id : String)
      User.get_all([staff_id], index: :staff_id).first?
    end

    secondary_index :sys_admin

    def self.find_sys_admins
      User.get_all([true], index: :sys_admin)
    end

    # Access Control
    ###############################################################################################

    def is_admin?
      !!(@sys_admin)
    end

    def is_support?
      !!(@support)
    end

    struct AdminAttributes
      include JSON::Serializable

      getter sys_admin : Bool?
      getter support : Bool?
      getter login_name : String?
      getter staff_id : String?
      getter card_number : String?
      getter groups : Array(String)?

      def apply(user : Model::User)
        set_if_present(sys_admin, user)
        set_if_present(support, user)
        set_if_present(login_name, user)
        set_if_present(staff_id, user)
        set_if_present(card_number, user)
        set_if_present(groups, user)
        user
      end

      private macro set_if_present(field, model)
        unless (%field = {{ field }}).nil?
          {{ model.id }}.{{ field.id }} = %field
        end
      end
    end

    # Publically visible fields
    PUBLIC_DATA = {
      :id, :email_digest, :nickname, :name, :first_name, :last_name,
      :country, :building, :image, {field: :created_at, serialise: :to_unix},
    }

    # Admin visible fields
    ADMIN_DATA = {
      # Public Visible
      :id, :email_digest, :nickname, :name, :first_name, :last_name,
      :country, :building, :image, {field: :created_at, serialise: :to_unix},
      # Admin Visible
      :sys_admin, :support, :email, :phone, :ui_theme, :misc, :login_name,
      :staff_id, :card_number, :groups,
    }

    subset_json(:as_public_json, PUBLIC_DATA)
    subset_json(:as_admin_json, ADMIN_DATA)

    # Password Encryption
    ###############################################################################################

    alias Password = Crypto::Bcrypt::Password

    before_save do
      # No password prevents people logging in using the account locally
      if pass = @password
        if pass.empty?
          @password_digest = nil
        else
          digest = Password.create(pass)
          self.password_digest = digest.to_s
        end
      end
      @password = nil
    end

    @pass_compare : Password? = nil

    def password : Password
      @pass_compare ||= Password.new(self.password_digest)
    end

    def password=(new_password : String) : String
      @pass_compare = digest = Password.create(new_password)
      self.password_digest = digest.to_s
      new_password
    end
  end
end
