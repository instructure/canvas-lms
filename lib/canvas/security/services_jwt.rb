module Canvas
  module Security
    class ServicesJwt
      attr_reader :token_string

      def initialize(raw_token_string)
        if raw_token_string.nil?
          raise ArgumentError, "Cannot decode nil token string"
        end
        @token_string = raw_token_string
      end

      def wrapper_token
        raw_wrapper_token = Canvas::Security.base64_decode(token_string)
        Canvas::Security.decode_jwt(raw_wrapper_token, [ENV['ECOSYSTEM_SECRET']])
      end

      def original_token
        original_crypted_token = wrapper_token[:user_token]
        Canvas::Security.decrypt_services_jwt(original_crypted_token)
      end

      def user_global_id
        original_token[:sub]
      end

      def self.generate(global_user_id)
        crypted_token = Canvas::Security.create_services_jwt(global_user_id)
        Canvas::Security.base64_encode(crypted_token)
      end
    end
  end
end
