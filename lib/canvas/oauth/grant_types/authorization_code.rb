# frozen_string_literal: true

module Canvas::OAuth
  module GrantTypes
    class AuthorizationCode < BaseType
      def supported_type?
        true
      end

      private

      def validate_type
        raise Canvas::OAuth::RequestError, :authorization_code_not_supplied unless @opts[:code]

        @_token = @provider.token_for(@opts[:code])
        raise Canvas::OAuth::RequestError, :invalid_authorization_code unless @_token.is_for_valid_code?
        raise Canvas::OAuth::RequestError, :incorrect_client unless [@_token.key.global_id, @_token.key.id].include? @_token.client_id
      end

      def generate_token
        @_token.create_access_token_if_needed(Canvas::Plugin.value_to_boolean(@opts[:replace_tokens]))
        Canvas::OAuth::Token.expire_code(@opts[:code])
        @_token
      end
    end
  end
end
