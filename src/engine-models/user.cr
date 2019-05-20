require "digest/md5"
require "scrypt"
require "time"

# Ruby libraries
# require 'email_validator'

require "../engine-models"

module Engine::Model
  class User < ModelBase
    table :user

    PUBLIC_DATA = {
      :id, :email_digest, :nickname, :name, :first_name, :last_name,
      :country, :building, :created_at,
    }

    attribute name : String, es_type: "keyword"
    attribute email : String
    attribute phone : String
    attribute country : String
    attribute image : String
    attribute metadata : String

    attribute login_name : String
    attribute staff_id : String
    attribute first_name : String
    attribute last_name : String
    attribute building : String

    attribute password_digest : Scrypt::Password, converter: Scrypt::Converter
    attribute email_digest : String
    attribute card_number : String

    attribute created_at : Time = ->{ Time.utc_now }, converter: Time::EpochConverter
    attribute deleted : Bool = false

    validates :email, presence: true
    validates :password, length: {minimum: 6, wrong_length: "must be at least 6 characters"}, allow_blank: true

    # belongs_to Authority
    # find_by_email(authority, email)
    # ensure_unique [:authority_id, :email], :email do |authority_id, email|
    #     "#{authority_id}-#{email.to_s.strip.downcase}"
    # end

    ensure_unique :login_name
    ensure_unique :staff_id

    def find_by_login_name(login_name)
      User.where(login_name: login_name)
    end

    def find_by_staff_id(staff_id)
      User.where(staff_id: staff_id)
    end

    # Create a secondary index on sys_admin field for quick lookup
    attribute sys_admin : Bool = false
    secondary_index :sys_admin

    attribute support : Bool = false

    before_save :build_name

    def build_name
      if self.first_name
        self.name = "#{self.first_name} #{self.last_name}"
      end
    end

    # ----------------
    # Indices
    # ----------------
    # index_view :authority_id
    # def self.all
    # by_authority_id
    # end

    def self.find_sys_admins
      User.get_all([true], index: :sys_admin)
    end

    # PASSWORD ENCRYPTION::
    # ---------------------

    attribute password : String, persistence: false
    validates :password, confirmation: true

    def authenticate(unencrypted_password)
      # accounts created with social logins will have an empty password_digest
      return nil if unencrypted_password.size == 0

      if (password_digest || "") == unencrypted_password
        self
      else
        nil
      end
    end

    # Encrypts the password into the password_digest attribute.
    def password=(unencrypted_password)
      @password = unencrypted_password
      unless unencrypted_password.empty?
        self.password_digest = ::Bcrypt::Password.create(unencrypted_password)
      end
    end

    # --------------------
    # END PASSWORD METHODS

    # Make reference to the email= function of the model
    def email=(new_email : String)
      # For looking up user pictures without making the email public
      self.email_digest = Digest::MD5.hexdigest(new_email)
    end
  end
end
