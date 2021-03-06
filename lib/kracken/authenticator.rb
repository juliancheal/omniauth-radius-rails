module Kracken
  class Authenticator
    attr_reader :auth_hash, :user_class

    ## Factory Methods

    # Login the user with their credentails. Used for proxying the
    # authentication to the auth server, normally from a mobile app
    def self.user_with_credentials(email, password)
      response = Kracken::CredentialAuthenticator.new.fetch(email, password)
      response ? self.new(response).to_app_user : nil
    end

    # Login the user with an auth token. Used for API authentication for the
    # public APIs
    def self.user_with_token(token)
      response = Kracken::TokenAuthenticator.new.fetch(token)
      response ? self.new(response).to_app_user : nil
    end

    def initialize(response)
      @auth_hash = create_auth_hash(response)
    end

    # Convert this Factory to a User object per the host app.
    def to_app_user
      raise MissingUIDError unless auth_hash.uid
      Kracken.config.user_class.find_or_create_from_auth_hash(auth_hash)
    end

    private

    def create_auth_hash(response_hash)
      Hashie::Mash.new({
        provider: response_hash['provider'],
        uid: response_hash['uid'],
        info: response_hash['info'],
        credentials: response_hash['credentials'],
      })
    end

  end
end
