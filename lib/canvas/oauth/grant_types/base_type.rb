# frozen_string_literal: true

module Canvas::OAuth
  module GrantTypes
    class BaseType
      attr_reader :opts, :provider

      def initialize(client_id, secret, opts)
        @secret = secret
        @provider = Canvas::OAuth::Provider.new(client_id)
        @opts = opts
      end

      def token
        validate_client_id_and_secret
        validate_type
        generate_token
      end

      # Unless otherwise specified by a sub-class, don't
      # allow public clients as defined in RFC 6749.
      def allow_public_client?
        false
      end

      def supported_type?
        false
      end

      private

      def validate_client_id_and_secret
        raise Canvas::OAuth::RequestError, :invalid_client_id unless @provider.has_valid_key?

        # Issue an access token if the grant type supports public client and the
        # DeveloperKey identifies a public client. Otherwise, the client must must
        # provide a client secret.
        return if allow_public_client? && @provider.key&.public_client? && @secret.blank?
        raise Canvas::OAuth::RequestError, :invalid_client_secret unless @provider.is_authorized_by?(@secret)
      end

      def validate_type
        raise "Abstract Method"
      end

      def generate_token
        raise "Abstract Method"
      end
    end
  end
end
