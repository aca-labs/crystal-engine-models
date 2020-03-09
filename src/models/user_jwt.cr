require "./base/jwt"

module PlaceOS::Model
  struct UserJWT < JWTBase
    getter iss : String

    @[JSON::Field(converter: Time::EpochConverter)]
    getter iat : Time

    @[JSON::Field(converter: Time::EpochConverter)]
    getter exp : Time

    # getter jti : String

    # Maps to authority domain
    getter aud : String

    # Maps to user id
    getter sub : String

    @[JSON::Field(key: "u")]
    getter user : Metadata

    enum Permissions
      User         = 0
      Support      = 1
      Admin        = 2
      AdminSupport = 3
    end

    struct Metadata
      include JSON::Serializable
      @[JSON::Field(key: "n")]
      getter name : String
      @[JSON::Field(key: "e")]
      getter email : String
      @[JSON::Field(key: "p")]
      getter permissions : Permissions

      def initialize(@name, @email, @permissions = Permissions::User)
      end
    end

    def initialize(@iss, @iat, @exp, @aud, @sub, @user)
    end

    def domain
      @aud
    end

    def id
      @sub
    end

    def is_admin?
      case @user.permissions
      when Permissions::Admin, Permissions::AdminSupport
        true
      else
        false
      end
    end

    def is_support?
      case @user.permissions
      when Permissions::Support, Permissions::AdminSupport
        true
      else
        false
      end
    end
  end
end
