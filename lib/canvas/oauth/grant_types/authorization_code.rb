module Canvas::Oauth
  module GrantTypes
    class AuthorizationCode < BaseType
      def supported_type?
        true
      end

      private

      def validate_type
        raise Canvas::Oauth::RequestError, :authorization_code_not_supplied unless @opts[:code]
        @_token = @provider.token_for(@opts[:code])
        raise Canvas::Oauth::RequestError, :invalid_authorization_code  unless @_token.is_for_valid_code?
        raise Canvas::Oauth::RequestError, :incorrect_client unless @_token.key.id == @_token.client_id
      end

      def generate_token
        @_token.create_access_token_if_needed(Canvas::Plugin.value_to_boolean(@opts[:replace_tokens]))
        Canvas::Oauth::Token.expire_code(@opts[:code])
        @_token
      end
    end
  end
end
