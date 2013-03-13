module Canvas::Oauth
  class Token
    attr_reader :key, :code

    REDIS_PREFIX = 'oauth2:'
    USER_KEY = 'user'
    CLIENT_KEY = 'client_id'

    def initialize(key, code)
      @key = key
      @code = code
    end

    def is_for_valid_code?
      code_data.present? &&  client_id == key.id
    end

    def client_id
      code_data[CLIENT_KEY]
    end

    def user
      @user ||= User.find(code_data[USER_KEY])
    end

    def code_data
      @code_data ||= JSON.parse(cached_code_entry)
    end

    def cached_code_entry
      Canvas.redis.get("#{REDIS_PREFIX}#{code}").presence || "{}"
    end

    def access_token
      @access_token ||= user.access_tokens.create!(:developer_key => key)
    end

    def to_json
      {
      'access_token' => access_token.full_token,
      'user' => user.as_json(:only => [:id, :name], :include_root => false),
      }
    end

    def self.generate_code_for(user_id, client_id)
      code = ActiveSupport::SecureRandom.hex(64)
      code_data = { USER_KEY => user_id, CLIENT_KEY => client_id }
      Canvas.redis.setex("#{REDIS_PREFIX}#{code}", 1.day, code_data.to_json)
      return code
    end

    def self.expire_code(code)
      Canvas.redis.del "#{REDIS_PREFIX}#{code}"
    end
  end
end
