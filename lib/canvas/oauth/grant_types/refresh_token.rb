# frozen_string_literal: true

module Canvas::OAuth
  module GrantTypes
    class RefreshToken < BaseType
      def supported_type?
        true
      end

      # Access tokens obtained by public clients through PKCE should
      # be refreshed using this grant type
      def allow_public_client?
        true
      end

      private

      def validate_type
        raise Canvas::OAuth::RequestError, :refresh_token_not_supplied unless @opts[:refresh_token]

        @_token = @provider.token_for_refresh_token(@opts[:refresh_token])
        raise Canvas::OAuth::RequestError, :invalid_refresh_token unless @_token
        raise Canvas::OAuth::RequestError, :incorrect_client unless @_token.access_token.developer_key_id == @_token.key.id
      end

      def generate_token
        @_token.access_token.regenerate_access_token

        if provider.key.public_client? && Account.site_admin.feature_enabled?(:pkce)
          # Access tokens for public clients have a (default) two-hour rolling window
          # in which tokens are eligible for refresh. When a refresh action is take for
          # a public client, extend that window by another two hours.
          @_token.access_token.set_permanent_expiration

          # For better token security, force public clients to rotate refresh tokens
          # after each use. This helps mitigate the risk of a leaked refresh token.
          @_token.access_token.generate_refresh_token(overwrite: true)
          @_token.access_token.save
        end

        @_token
      end
    end
  end
end
