#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Canvas::Security
  class InvalidToken < RuntimeError
  end

  class TokenExpired < RuntimeError
  end

  def self.encryption_key
    @encryption_key ||= begin
      res = config && config['encryption_key']
      abort('encryption key required, see security.yml.example') unless res
      abort('encryption key is too short, see security.yml.example') unless res.to_s.length >= 20
      res.to_s
    end
  end

  def self.encryption_keys
    @encryption_keys ||= [encryption_key] + Array(config && config['previous_encryption_keys']).map(&:to_s)
  end

  def self.config
    @config ||= (YAML.load_file(Rails.root+"config/security.yml")[Rails.env] rescue nil)
  end
  
  def self.encrypt_password(secret, key)
    require 'base64'
    c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    c.encrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + encryption_key)
    c.iv = iv = c.random_iv
    e = c.update(secret)
    e << c.final
    [Base64.encode64(e), Base64.encode64(iv)]
  end
  
  def self.decrypt_password(secret, salt, key, encryption_key = nil)
    require 'base64'
    encryption_keys = Array(encryption_key) + self.encryption_keys
    last_error = nil
    encryption_keys.each do |encryption_key|
      c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      c.decrypt
      c.key = Digest::SHA1.hexdigest(key + "_" + encryption_key)
      c.iv = Base64.decode64(salt)
      d = c.update(Base64.decode64(secret))
      begin
        d << c.final
      rescue OpenSSL::Cipher::CipherError
        last_error = $!
        next
      end
      return d.to_s
    end
    raise last_error
  end
  
  def self.hmac_sha1(str, encryption_key = nil)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'), (encryption_key || self.encryption_key), str
    )
  end

  def self.verify_hmac_sha1(hmac, str, options = {})
    keys = options[:keys] || []
    keys += [options[:key]] if options[:key]
    keys += encryption_keys
    keys.each do |key|
      real_hmac = hmac_sha1(str, key)
      real_hmac = real_hmac[0, options[:truncate]] if options[:truncate]
      return true if hmac == real_hmac
    end
    false
  end

  # Creates a JWT token string
  #
  # body (Hash) - The contents of the JWT token
  # expires (Time) - When the token should expire. `nil` for no expiration
  # key (String) - The key to sign with. `nil` will use the currently configured key
  #
  # Returns the token as a string.
  def self.create_jwt(body, expires = nil, key = nil)
    jwt_body = body
    if expires
      jwt_body = jwt_body.merge({ exp: expires.to_i })
    end
    JWT.encode(jwt_body, key || encryption_key)
  end

  # Verifies and decodes a JWT token
  #
  # token (String) - The token to decode
  # keys (Array) - An array of keys to use verifying. Will be added to the current
  #                set of keys
  #
  # Returns the token body as a Hash if it's valid.
  #
  # Raises Canvas::Security::TokenExpired if the token has expired, and
  # Canvas::Security::InvalidToken if the token is otherwise invalid.
  def self.decode_jwt(token, keys = [])
    keys += encryption_keys

    keys.each do |key|
      begin
        body = JWT.decode(token, key)[0]
        return body.with_indifferent_access
      rescue JWT::ExpiredSignature
        raise Canvas::Security::TokenExpired
      rescue JWT::DecodeError
        # Keep looping, to try all the keys. If none succeed,
        # we raise below.
      end
    end

    raise Canvas::Security::InvalidToken
  end

  def self.validate_encryption_key(overwrite = false)
    db_hash = Setting.get('encryption_key_hash', nil) rescue return # in places like rake db:test:reset, we don't care that the db/table doesn't exist
    return if encryption_keys.any? { |key| Digest::SHA1.hexdigest(key) == db_hash}

    if db_hash.nil? || overwrite
      Setting.set("encryption_key_hash", Digest::SHA1.hexdigest(encryption_key))
    else
      abort "encryption key is incorrect. if you have intentionally changed it, you may want to run `rake db:reset_encryption_key_hash`"
    end
  end

  def self.re_encrypt_data(encryption_key)
    {
        Account =>  {
            :encrypted_column => :turnitin_crypted_secret,
            :salt_column => :turnitin_salt,
            :key => 'instructure_turnitin_secret_shared' },
        AccountAuthorizationConfig => {
            :encrypted_column => :auth_crypted_password,
            :salt_column => :auth_password_salt,
            :key => 'instructure_auth' },
        UserService => {
            :encrypted_column => :crypted_password,
            :salt_column => :password_salt,
            :key => 'instructure_user_service' },
        User => {
            :encrypted_column => :otp_secret_key_enc,
            :salt_column => :otp_secret_key_salt,
            :key => 'otp_secret_key'
        }
    }.each do |(model, definition)|
      model.where("#{definition[:encrypted_column]} IS NOT NULL").
          select([:id, definition[:encrypted_column], definition[:salt_column]]).
          find_each do |instance|
        cleartext = Canvas::Security.decrypt_password(instance.read_attribute(definition[:encrypted_column]),
                                                      instance.read_attribute(definition[:salt_column]),
                                                      definition[:key],
                                                      encryption_key)
        new_crypted_data, new_salt = Canvas::Security.encrypt_password(cleartext, definition[:key])
        model.where(:id => instance).
            update_all(definition[:encrypted_column] => new_crypted_data,
                       definition[:salt_column] => new_salt)
      end
    end

    PluginSetting.find_each do |settings|
      unless settings.plugin
        warn "Unknown plugin #{settings.name}"
        next
      end
      Array(settings.plugin.encrypted_settings).each do |setting|
        cleartext = Canvas::Security.decrypt_password(settings.settings["#{setting}_enc".to_sym],
                                                      settings.settings["#{setting}_salt".to_sym],
                                                      'instructure_plugin_setting',
                                                      encryption_key)
        new_crypted_data, new_salt = Canvas::Security.encrypt_password(cleartext, 'instructure_plugin_setting')
        settings.settings["#{setting}_enc".to_sym] = new_crypted_data
        settings.settings["#{setting}_salt".to_sym] = new_salt
        settings.settings_will_change!
      end
      settings.save! if settings.changed?
    end
  end

  # should we allow this login attempt -- returns false if there have been too
  # many recent failed attempts for this pseudonym. Failed attempts are tracked
  # by both (pseudonym) and (pseudonym, requesting_ip) , with the latter having
  # a lower threshold. This way a malicious user can't trivially lock out
  # another user by just making a bunch of bogus requests, they'll be blocked
  # themselves first. A distributed attack would still succeed in locking out
  # the user.
  #
  # in redis this is stored as a hash :
  # { 'unique_id' => pseudonym.unique_id, # for debugging
  #   'total' => <total failed attempts>,
  #   some_ip => <failed attempts for this ip>,
  #   some_other_ip => <failed attempts for this ip>,
  #   ...
  # }
  def self.allow_login_attempt?(pseudonym, ip)
    return true unless Canvas.redis_enabled? && pseudonym
    ip.present? || ip = 'no_ip'
    total_allowed = Setting.get('login_attempts_total', '20').to_i
    ip_allowed = Setting.get('login_attempts_per_ip', '10').to_i
    total, from_this_ip = Canvas.redis.hmget(login_attempts_key(pseudonym), 'total', ip)
    return (!total || total.to_i < total_allowed) && (!from_this_ip || from_this_ip.to_i < ip_allowed)
  end

  # log a successful login, resetting the failed login attempts counter
  def self.successful_login!(pseudonym, ip)
    return unless Canvas.redis_enabled? && pseudonym
    Canvas.redis.del(login_attempts_key(pseudonym))
    nil
  end

  # log a failed login attempt
  def self.failed_login!(pseudonym, ip)
    return unless Canvas.redis_enabled? && pseudonym
    key = login_attempts_key(pseudonym)
    exptime = Setting.get('login_attempts_ttl', 5.minutes.to_s).to_i
    redis = Canvas.redis
    redis.hset(key, 'unique_id', pseudonym.unique_id)
    redis.hincrby(key, 'total', 1)
    redis.hincrby(key, ip, 1) if ip.present?
    redis.expire(key, exptime)
    nil
  end

  # returns time in seconds
  def self.time_until_login_allowed(pseudonym, ip)
    if self.allow_login_attempt?(pseudonym, ip)
      0
    else
      Canvas.redis.ttl(login_attempts_key(pseudonym))
    end
  end

  def self.login_attempts_key(pseudonym)
    "login_attempts:#{pseudonym.global_id}"
  end
end
