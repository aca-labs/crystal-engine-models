require "./base/jwt"

module ACAEngine::Model
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

    getter user : Metadata

    struct Metadata
      include JSON::Serializable
      getter name : String
      getter email : String
      getter admin : Bool
      getter support : Bool

      def initialize(@name, @email, @admin, @support)
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
      @user.admin
    end

    def is_support?
      @user.support
    end
  end
end
