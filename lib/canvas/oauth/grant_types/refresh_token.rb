module Canvas::Oauth
  module GrantTypes
    class RefreshToken < BaseType
      def supported_type?
        true
      end

      private

      def validate_type
        raise Canvas::Oauth::RequestError, :refresh_token_not_supplied unless @opts[:refresh_token]
        @_token = @provider.token_for_refresh_token(@opts[:refresh_token])
        raise Canvas::Oauth::RequestError, :invalid_refresh_token unless @_token
        raise Canvas::Oauth::RequestError, :incorrect_client unless @_token.access_token.developer_key_id == @_token.key.id
      end

      def generate_token
        # don't regenerate if recently changed
        if update_recently_refreshed_tokens? || @_token.access_token.updated_at < recent_refresh_threshold
          @_token.access_token.regenerate_access_token
        end
        @_token
      end

      def update_recently_refreshed_tokens?
        Rails.env.test? # keep old behavior only for specs
      end

      def recent_refresh_threshold
        Setting.get("oauth_refresh_token_spam_interval", "5").to_i.seconds.ago
      end
    end
  end
end
