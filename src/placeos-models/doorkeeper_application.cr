require "json"
require "time"
require "uuid"

require "random/secure"
require "./base/model"
require "digest/md5"

module PlaceOS::Model
  class DoorkeeperApplication < ModelBase
    include RethinkORM::Timestamps

    table :doorkeeper_app

    attribute name : String, es_type: "keyword"
    attribute secret : String
    attribute scopes : String = "public"
    attribute owner_id : String, es_type: "keyword"
    attribute redirect_uri : String
    attribute skip_authorization : Bool = true
    attribute confidential : Bool = false
    attribute revoked_at : Time, converter: Time::EpochConverter

    attribute uid : String
    ensure_unique :uid, create_index: true

    validates :name, presence: true
    validates :secret, presence: true
    validates :redirect_uri, presence: true

    before_create :generate_secret
    before_save :generate_uid

    def generate_uid
      check_uid = self.uid
      redirect = self.redirect_uri.try &.downcase
      if check_uid.nil? || check_uid.try &.blank?
        if redirect && redirect.starts_with?("http")
          self.uid = Digest::MD5.hexdigest(redirect)
        else
          self.uid = Random::Secure.urlsafe_base64(25)
        end
      end
    end

    def generate_secret
      self.secret = Random::Secure.urlsafe_base64(40)
    end
  end
end
