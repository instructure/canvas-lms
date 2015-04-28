module Canvas::Oauth
  class Token
    attr_reader :key, :code

    REDIS_PREFIX = 'oauth2:'
    USER_KEY = 'user'
    CLIENT_KEY = 'client_id'
    SCOPES_KEY = 'scopes'
    PURPOSE_KEY = 'purpose'
    REMEMBER_ACCESS = 'remember_access'

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

    def scopes
      @scopes ||= code_data[SCOPES_KEY] || []
    end

    def purpose
      code_data[PURPOSE_KEY]
    end

    def remember_access?
      @remember_access ||= !!code_data[REMEMBER_ACCESS]
    end

    def code_data
      @code_data ||= JSON.parse(cached_code_entry)
    end

    def cached_code_entry
      Canvas.redis.get("#{REDIS_PREFIX}#{code}").presence || "{}"
    end

    def create_access_token_if_needed(replace_tokens = false)
      @access_token ||= self.class.find_reusable_access_token(user, key, scopes, purpose)

      if @access_token.nil?
        # Clear other tokens issued under the same developer key if requested
        user.access_tokens.where(developer_key_id: key).destroy_all if replace_tokens || key.replace_tokens

        # Then create a new one
        @access_token = user.access_tokens.create!({:developer_key => key, :remember_access => remember_access?, :scopes => scopes, :purpose => purpose})

        @access_token.clear_full_token! if @access_token.scoped_to?(['userinfo'])
      end
    end

    def access_token
      create_access_token_if_needed
      @access_token
    end

    def self.find_reusable_access_token(user, key, scopes, purpose)
      if key.force_token_reuse
        find_access_token(user, key, scopes, purpose)
      elsif AccessToken.scopes_match?(scopes, ["userinfo"])
        find_userinfo_access_token(user, key, purpose)
      end
    end

    def as_json(options={})
      {
        'access_token' => access_token.full_token,
        'user' => user.as_json(:only => [:id, :name], :include_root => false),
      }
    end

    def self.find_userinfo_access_token(user, developer_key, purpose)
      find_access_token(user, developer_key, ["userinfo"], purpose, {remember_access: true})
    end

    def self.find_access_token(user, developer_key, scopes, purpose, conditions = {})
      user.shard.activate do
        user.access_tokens.active.where({:developer_key_id => developer_key, :purpose => purpose}.merge(conditions)).detect do |token|
          token.scoped_to?(scopes)
        end
      end
    end

    def self.generate_code_for(user_id, client_id, options = {})
      code = SecureRandom.hex(64)
      code_data = {
        USER_KEY => user_id,
        CLIENT_KEY => client_id,
        SCOPES_KEY => options[:scopes],
        PURPOSE_KEY => options[:purpose],
        REMEMBER_ACCESS => options[:remember_access] }
      Canvas.redis.setex("#{REDIS_PREFIX}#{code}", Setting.get('oath_token_request_timeout', 10.minutes.to_s).to_i, code_data.to_json)
      return code
    end

    def self.expire_code(code)
      Canvas.redis.del "#{REDIS_PREFIX}#{code}"
    end
  end
end
