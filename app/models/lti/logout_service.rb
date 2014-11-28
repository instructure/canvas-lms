require 'net/http'

module Lti
  class LogoutService
    # the register-logout-callback token expiration time in seconds
    TOKEN_EXPIRATION = 600

    def self.cache_key(pseudonym)
      ['logout_service_callbacks_2', pseudonym.id].cache_key
    end

    def self.get_logout_callbacks(pseudonym)
      Rails.cache.read(cache_key(pseudonym)) || {}
    end

    def self.clear_logout_callbacks(pseudonym)
      Rails.cache.delete(cache_key(pseudonym))
    end

    class Token < Struct.new(:tool, :pseudonym, :timestamp, :nonce)
      def self.create(tool, pseudonym)
        Token.new(tool, pseudonym, Time.now, SecureRandom.hex(8))
      end

      def serialize
        key = tool.shard.settings[:encryption_key]
        payload = [tool.id, pseudonym.id, timestamp.to_i, nonce].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload, key)}"
      end

      def self.parse_and_validate(serialized_token)
        parts = serialized_token.split('-')
        tool = ContextExternalTool.find(parts[0].to_i)
        key = tool.shard.settings[:encryption_key]
        unless parts.size == 5 && Canvas::Security.hmac_sha1(parts[0..-2].join('-'), key) == parts[-1]
          raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid logout service token"
        end
        pseudonym = Pseudonym.find(parts[1].to_i)
        timestamp = parts[2].to_i
        nonce = parts[3]
        unless Time.now.to_i - timestamp < Lti::LogoutService::TOKEN_EXPIRATION
          raise BasicLTI::BasicOutcomes::Unauthorized, "Logout service token has expired"
        end
        Token.new(tool, pseudonym, timestamp, nonce)
      end
    end

    class Runner < Struct.new(:callbacks)
      def perform
        callbacks.each do |tool_id, callback|
          begin
            CanvasHttp.get(URI.parse(callback).to_s)
          rescue => e
            Rails.logger.error("Failed to call logout callback '#{callback}': #{e.inspect}")
          end
        end
      end
    end

    def self.create_token(tool, pseudonym)
      Token.create(tool, pseudonym).serialize
    end

    def self.register_logout_callback(token, callback)
      return unless token.pseudonym && token.pseudonym.id && callback.present?
      callbacks = get_logout_callbacks(token.pseudonym)
      raise BasicLTI::BasicOutcomes::Unauthorized, 'Logout service token has already been used' if callbacks.has_key?(token.nonce)
      callbacks[token.nonce] = callback
      Rails.cache.write(cache_key(token.pseudonym), callbacks, :expires_in => 1.day)
    end

    def self.queue_callbacks(pseudonym)
      return unless pseudonym && pseudonym.id
      callbacks = get_logout_callbacks(pseudonym)
      return unless callbacks.any?
      clear_logout_callbacks(pseudonym)
      Delayed::Job.enqueue(Lti::LogoutService::Runner.new(callbacks), max_attempts: 1)
    end
  end
end
