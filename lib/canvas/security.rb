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
  def self.encryption_key
    @encryption_key ||= begin
      res = config && config['encryption_key']
      abort('encryption key required, see security.yml.example') unless res
      abort('encryption key is too short, see security.yml.example') unless res.to_s.length >= 20
      res.to_s
    end
  end
  
  def self.config
    @config ||= (YAML.load_file(Rails.root+"config/security.yml")[Rails.env] rescue nil)
  end
  
  def self.encrypt_password(secret, key, encryption_key = nil)
    require 'base64'
    c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    c.encrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + (encryption_key || self.encryption_key))
    c.iv = iv = c.random_iv
    e = c.update(secret)
    e << c.final
    [Base64.encode64(e), Base64.encode64(iv)]
  end
  
  def self.decrypt_password(secret, salt, key, encryption_key = nil)
    require 'base64'
    c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    c.decrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + (encryption_key || self.encryption_key))
    c.iv = Base64.decode64(salt)
    d = c.update(Base64.decode64(secret))
    d << c.final
    d.to_s
  end
  
  def self.hmac_sha1(str, encryption_key = nil)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'), (encryption_key || self.encryption_key), str
    )
  end

  def self.verify_hmac_sha1(hmac, str)
    hmac == hmac_sha1(str)
  end

  def self.validate_encryption_key(overwrite = false)
    config_hash = Digest::SHA1.hexdigest(Canvas::Security.encryption_key)
    db_hash = Setting.get('encryption_key_hash', nil) rescue return # in places like rake db:test:reset, we don't care that the db/table doesn't exist
    return if db_hash == config_hash

    if db_hash.nil? || overwrite
      Setting.set("encryption_key_hash", config_hash)
    else
      abort "encryption key is incorrect. if you have intentionally changed it, you may want to run `rake db:reset_encryption_key_hash`"
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
