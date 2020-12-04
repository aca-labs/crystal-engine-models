require "random"

require "./base/model"

module PlaceOS::Model
  class Edge < ModelBase
    include RethinkORM::Timestamps

    table :edge

    attribute name : String, es_subfield: "keyword"

    attribute description : String = ""

    attribute secret : String = ->{ Random::Secure.hex(64) }

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

    def token(user : Model::User)
      "#{self.id}_#{decrypt_secret_for(user)}"
    end

    # Encrypt all encrypted attributes
    def encrypt!
      self.secret = encrypt_secret
      self
    end

    # Decrypt all encrypted attributes
    def decrypt_for!(user)
      self.secret = decrypt_secret_for(user)
      sself
    end

    def check_secret?(test : String) : Bool
      Encryption.check?(encrypted: secret, test: test, level: ENCRYPTION_LEVEL, id: "")
    end

    def encrypt_secret
      Encryption.encrypt(string: secret, level: ENCRYPTION_LEVEL, id: "")
    end

    def decrypt_secret_for(user)
      Encryption.decrypt_for(user: user, string: secret, level: ENCRYPTION_LEVEL, id: "")
    end
  end
end
