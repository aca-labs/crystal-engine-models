require "time"

# Ruby libraries
# require 'email_validator'
# require 'digest/md5'
# require 'scrypt'

require "../engine-models"

module Engine::Model
  class Zone < ModelBase
    table :user

    PUBLIC_DATA = {
      :id, :email_digest, :nickname, :name, :first_name, :last_name,
      :country, :building, :created_at,
    }

    attribute name : String
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

    attribute password_digest : String
    attribute email_digest : String
    attribute card_number : String

    attribute created_at : Time = ->{ Time.now }, converter: Time::EpochConverter
    attribute deleted : Bool = false

    # belongs_to Authority
    # find_by_email(authority, email)
    # ensure_unique [:authority_id, :email], :email do |authority_id, email|
    #     "#{authority_id}-#{email.to_s.strip.downcase}"
    # end

    # find_by_login_name(login)
    ensure_unique :login_name
    ensure_unique :staff_id

    # Create a secondary index on sys_admin field for quick lookup
    secondary_index :sys_admin
    attribute sys_admin : Bool = false

    attribute support : Bool = false

    before_save :build_name

    def build_name
      if self.first_name
        self.name = "#{self.first_name} #{self.last_name}"
      end
    end

    # ----------------
    # indexes
    # ----------------
    # index_view :authority_id
    # def self.all
    # by_authority_id
    # end
    def self.find_sys_admins
      User.get_all([true], index: :sys_admin)
    end

    # FIXME: Encryption methods

    # PASSWORD ENCRYPTION::
    # ---------------------
    # getter :password
    # validates_confirmation_of :password
    # if respond_to?(:attributes_protected_by_default)
    #     def self.attributes_protected_by_default
    #         super + ['password_digest']
    #     end
    # end

    # def authenticate(unencrypted_password)
    #     if ::SCrypt::Password.new(password_digest || '') == unencrypted_password
    #         self
    #     else
    #         false
    #     end
    # rescue ::SCrypt::Errors::InvalidHash
    #     # accounts created with social logins will have an empty password_digest
    #     # which causes SCrypt to raise an InvalidHash exception
    #     false
    # end

    # # Encrypts the password into the password_digest attribute.
    # def password=(unencrypted_password)
    #     @password = unencrypted_password
    #     unless unencrypted_password.empty?
    #         self.password_digest = ::SCrypt::Password.create(unencrypted_password)
    #     end
    # end
    # --------------------
    # END PASSWORD METHODS

    # FIXME: Email methods
    # Make reference to the email= function of the model
    # alias_method :assign_email, :email=
    # def email=(new_email)
    #     assign_email(new_email)

    #     # For looking up user pictures without making the email public
    #     self.email_digest = Digest::MD5.hexdigest(new_email) if new_email
    # end

    # protected validates :email, :email => true
    # protected validates :password, length: { minimum: 6, message: 'must be at least 6 characters' }, allow_blank: true
  end
end
