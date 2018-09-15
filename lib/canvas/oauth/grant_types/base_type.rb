module Canvas::Oauth
  module GrantTypes
    class BaseType
      def initialize(client_id, secret, opts)
        @secret = secret
        @provider = Canvas::Oauth::Provider.new(client_id)
        @opts = opts
      end

      def token
        validate_client_id_and_secret
        validate_type
        generate_token
      end

      def supported_type?
        false
      end

      private

      def validate_client_id_and_secret
        raise Canvas::Oauth::RequestError, :invalid_client_id unless @provider.has_valid_key?
        raise Canvas::Oauth::RequestError, :invalid_client_secret unless @provider.is_authorized_by?(@secret)
      end

      def validate_type
        raise 'Abstract Method'
      end

      def generate_token
        raise 'Abstract Method'
      end
    end
  end
end
