require "CrystalEmail"
require "digest/md5"
require "rethinkdb-orm"
require "crypto/bcrypt/password"
require "./authority"
require "./base/model"

module PlaceOS::Model
  class User < ModelBase
    include RethinkORM::Timestamps
    table :user

    belongs_to Authority

    attribute name : String, es_type: "keyword"
    attribute nickname : String
    attribute email : String
    attribute phone : String
    attribute country : String
    attribute image : String
    attribute ui_theme : String
    attribute metadata : String

    attribute login_name : String
    attribute staff_id : String
    attribute first_name : String
    attribute last_name : String
    attribute building : String

    attribute password_digest : String, mass_assignment: false
    attribute email_digest : String, mass_assignment: false
    attribute card_number : String

    attribute deleted : Bool = false
    attribute groups : Array(String) = [] of String, mass_assignment: false

    attribute access_token : String, mass_assignment: false
    attribute refresh_token : String, mass_assignment: false
    attribute expires_at : Int64, mass_assignment: false
    attribute expires : Bool, mass_assignment: false

    attribute password : String

    has_many(
      child_class: UserAuthLookup,
      dependent: :destroy,
      foreign_key: "user_id",
      collection_name: :auth_lookups
    )

    validates :email, presence: true
    validates :authority_id, presence: true

    # Validate email format
    validate ->(this : User) {
      return unless (email = this.email)
      this.validation_error(:email, "is an invalid email") unless email.is_email?
    }

    before_save :create_email_digest
    before_destroy :cleanup_auth_tokens

    # Sets email_digest to allow user look up without leaking emails
    #
    protected def create_email_digest
      self.email_digest = Digest::MD5.hexdigest(self.email.as(String))
    end

    # deletes auth tokens
    def cleanup_auth_tokens
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

    secondary_index :email

    def self.find_by_email(authority_id : String, email : String)
      User.where(email: email, authority_id: authority_id).first?
    end

    # Ensure email is unique, prepends authority id for searching
    #
    ensure_unique :email, scope: [:authority_id, :email] do |authority_id, email|
      {authority_id, email.strip.downcase}
    end

    ensure_unique :login_name, scope: [:authority_id, :login_name] do |authority_id, login_name|
      {authority_id, login_name.strip.downcase}
    end

    ensure_unique :staff_id, scope: [:authority_id, :staff_id] do |authority_id, staff_id|
      {authority_id, staff_id.strip.downcase}
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
      :sys_admin, :support, :email, :phone, :ui_theme, :metadata, :login_name,
      :staff_id, :card_number, :groups
    }

    subset_json(:as_public_json, PUBLIC_DATA)
    subset_json(:as_admin_json, ADMIN_DATA)

    secondary_index :login_name

    def self.find_by_login_name(login_name : String)
      User.get_all([login_name], index: :login_name).first?
    end

    secondary_index :staff_id

    def self.find_by_staff_id(staff_id : String)
      User.get_all([staff_id], index: :staff_id).first?
    end

    attribute sys_admin : Bool = false

    attribute support : Bool = false

    def is_admin?
      !!(@sys_admin)
    end

    def is_support?
      !!(@support)
    end

    before_save :build_name

    def build_name
      if self.first_name
        self.name = "#{self.first_name} #{self.last_name}"
      end
    end

    # ----------------
    # Indices
    # ----------------

    secondary_index :authority_id

    def by_authority_id(auth_id : String)
      User.get_all([auth_id], index: :authority_id)
    end

    secondary_index :sys_admin

    def self.find_sys_admins
      User.get_all([true], index: :sys_admin)
    end

    # PASSWORD ENCRYPTION::
    # ---------------------
    alias Password = Crypto::Bcrypt::Password

    before_save do
      if pass = @password
        # no password prevents people logging in using the account locally
        if pass.empty?
          self.password_digest = nil
        else
          digest = Password.create(pass)
          self.password_digest = digest.to_s
        end
      end
      @password = nil
    end

    @pass_compare : Password? = nil

    def password : Password
      @pass_compare ||= Password.new(self.password_digest.not_nil!)
    end

    def password=(new_password : String) : String
      @pass_compare = digest = Password.create(new_password)
      self.password_digest = digest.to_s
      new_password
    end
  end
end
