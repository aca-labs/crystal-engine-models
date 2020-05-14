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
    attribute owner_id : String
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
      self.uid = Digest::MD5.hexdigest(self.redirect_uri.not_nil!)
    end

    def generate_secret
      self.secret = Random::Secure.urlsafe_base64(40)
    end
  end
end
