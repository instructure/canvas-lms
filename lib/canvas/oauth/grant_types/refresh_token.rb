# frozen_string_literal: true

module Canvas::OAuth
  module GrantTypes
    class RefreshToken < BaseType
      def supported_type?
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
        @_token
      end
    end
  end
end
