module Canvas::Oauth
  class Provider
    OAUTH2_OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'


    attr_reader :client_id, :redirect_uri, :scopes, :purpose

    def initialize(client_id, redirect_uri = "", scopes = [], purpose = nil)
      @client_id = client_id
      @redirect_uri = redirect_uri
      @scopes = scopes
      @purpose = purpose
    end

    def has_valid_key?
      key.present?
    end

    def client_id_is_valid?
      return false unless @client_id.present?
      begin
        !!Integer(@client_id)
      rescue ArgumentError
        false
      end
    end

    def is_authorized_by?(secret)
      secret == key.api_key
    end

    def has_valid_redirect?
      self.class.is_oob?(redirect_uri) || key.redirect_domain_matches?(redirect_uri)
    end

    def icon_url
      key.icon_url
    end

    def key
      return nil unless client_id_is_valid?
      @key ||= DeveloperKey.where(id: @client_id).first
    end

    # Checks to see if a token has already been issued to this client and
    # if we can reissue the same token to that client without asking for
    # user permission again. If the developer key is trusted, access
    # tokens will be automatically authorized without prompting the end-
    # user
    def authorized_token?(user)
      if !self.class.is_oob?(redirect_uri)
        return true if Token.find_reusable_access_token(user, key, scopes, purpose)
        return true if key.trusted?
      end

      return false
    end

    def token_for(code)
      Token.new(key, code)
    end

    def app_name
      key.name.presence || key.user_name.presence || key.email.presence || default_app_name
    end

    def redirect_uri
      @redirect_uri.presence || ""
    end

    def session_hash
      { :client_id => key.id, :redirect_uri => redirect_uri, :scopes => scopes, :purpose => purpose }
    end

    def self.is_oob?(uri)
      uri == OAUTH2_OOB_URI
    end

    private
    def default_app_name
      I18n.translate('pseudonym_sessions.default_app_name', 'Third-Party Application')
    end

   
  end
end
