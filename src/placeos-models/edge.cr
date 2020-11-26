require "random"

require "./base/model"

module PlaceOS::Model
  class Edge < ModelBase
    include RethinkORM::Timestamps

    table :edge

    attribute name : String, es_subfield: "keyword"

    attribute description : String = ""

    attribute secret : String = ->{ Random::Secure.hex(64) }

    attribute salt : String = ->{ Random::Secure.hex(5) }

    ENCRYPTION_LEVEL = Encryption::Level::Admin

    before_save :encrypt!

    ensure_unique :name do |name|
      name.strip
    end

    ensure_unique :secret

    # Modules allocated to this Edge
    has_many(
      child_class: Module,
      collection_name: "modules",
      foreign_key: "edge_id",
    )

    def valid?(test : String) : Bool
      Encryption.decrypt(string: secret, id: salt, level: ENCRYPTION_LEVEL) == test
    end

    def encrypt
      Encryption.encrypt(string: secret, level: ENCRYPTION_LEVEL, id: salt)
    end

    def encrypt!
      self.secret = encrypt
      self
    end

    def decrypt_for(user)
      Encryption.decrypt_for(user: user, string: secret, level: ENCRYPTION_LEVEL, id: salt)
    end

    def decrypt_for!(user)
      self.secret = decrypt_for(user)
      self
    end
  end
end
