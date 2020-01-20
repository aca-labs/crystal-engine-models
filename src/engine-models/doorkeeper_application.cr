require "uuid"
require "json"
require "./base/model"

module ACAEngine::Model
  class DoorkeeperApplication < ModelBase
    include RethinkORM::Timestamps

    table :doorkeeper_app

    attribute name : String, es_type: "keyword"
    attribute secret : String
    attribute scopes : String = "public"
    attribute owner_id : String
    attribute redirect_uri : String
    attribute skip_authorization : Bool = false
    attribute confidential : Bool = false
    attribute revoked_at : Integer

    attribute uid : String
    ensure_unique :uid, create_index: true

    validates :name, presence: true

    before_save :generate_uid

    def generate_uid
      blank = uid.nil? || uid.try &.blank?
      self.uid = UUID.random.to_s if blank
    end
  end
end
