require 'net/http'

module Lti
  class LogoutService
    # the register-logout-callback token expiration time in seconds
    TOKEN_EXPIRATION = 600

    def self.cache_key(pseudonym)
      ['logout_service_callbacks', pseudonym.id].cache_key
    end

    def self.get_logout_callbacks(pseudonym)
      Rails.cache.read(cache_key(pseudonym)) || []
    end

    def self.clear_logout_callbacks(pseudonym)
      Rails.cache.delete(cache_key(pseudonym))
    end

    class Token < Struct.new(:tool, :pseudonym, :timestamp)
      def serialize
        key = tool.shard.settings[:encryption_key]
        payload = [tool.id, pseudonym.id, timestamp.to_i].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload, key)}"
      end

      def self.parse_and_validate(serialized_token)
        parts = serialized_token.split('-')
        tool = ContextExternalTool.find(parts[0].to_i)
        key = tool.shard.settings[:encryption_key]
        unless parts.size == 4 && Canvas::Security.hmac_sha1(parts[0..-2].join('-'), key) == parts[-1]
          raise BasicLTI::BasicOutcomes::Unauthorized, "Invalid logout service token"
        end
        pseudonym = Pseudonym.find(parts[1].to_i)
        timestamp = parts[2].to_i
        unless Time.now.to_i - timestamp < Lti::LogoutService::TOKEN_EXPIRATION
          raise BasicLTI::BasicOutcomes::Unauthorized, "Logout service token has expired"
        end
        Token.new(tool, pseudonym, timestamp)
      end
    end

    class Runner < Struct.new(:callbacks)
      def perform
        callbacks.each do |callback|
          begin
            Net::HTTP::get(URI.parse(callback))
          rescue => e
            Rails.logger.error("Failed to call logout callback '#{callback}': #{e.inspect}")
          end
        end
      end
    end

    def self.create_token(tool, pseudonym)
      Token.new(tool, pseudonym, Time.now).serialize
    end

    def self.register_logout_callback(pseudonym, callback)
      return unless pseudonym && pseudonym.id
      callbacks = get_logout_callbacks(pseudonym)
      callbacks << callback
      Rails.cache.write(cache_key(pseudonym), callbacks, :expires_in => 1.day)
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
