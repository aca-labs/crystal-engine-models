require "random"

require "./base/model"

module PlaceOS::Model
  class Edge < ModelBase
    include RethinkORM::Timestamps

    table :edge

    attribute name : String, es_subfield: "keyword"

    attribute description : String = ""

    attribute secret : String = ->{ Random::Secure.base64(64) }, mass_assignment: false

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

    # Yield a token if the user has privileges
    #
    def token(user : Model::User) : String?
      return unless user.is_admin?
      Base64.urlsafe_encode("#{self.id}_#{decrypt_secret_for(user)}")
    end

    def self.validate_token?(token : String) : String?
      parts = Base64.decode_string(token).split('_') rescue nil

      if parts.nil? || parts.size != 2
        Log.info { {message: "deformed token", token: token} }
        return
      end

      edge_id, secret = parts
      if (edge = Model::Edge.find(edge_id)).nil?
        Log.info { {message: "edge not found", edge_id: edge_id} }
        return
      end

      if edge.check_secret?(secret)
        edge_id
      else
        Log.info { {message: "edge secret is invalid", edge_id: edge_id} }
        nil
      end
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
