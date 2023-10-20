# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "active_support/core_ext/module"
require "json/jwt"
require "dynamic_settings"
require "canvas_errors"
require "canvas_security/jwk_key_pair"
require "canvas_security/jwt_workflow"
require "canvas_security/key_storage"
require "canvas_security/page_view_jwt"
require "canvas_security/rsa_key_pair"
require "canvas_security/services_jwt"

module CanvasSecurity
  class UnconfiguredError < StandardError; end

  # TODO: Maybe at one point Setting will be
  # a gem on it's own or some other dependable module.
  # For the moment, this is a convenient way to inject
  # this base class without needing to depend on it directly.
  mattr_writer :settings_store
  mattr_accessor :region, :environment

  # Expected interface for this object is:
  #   object.get(setting_name, 'default_value') # [ returning a string ]
  #
  # In this instance, it's expected that canvas is going to inject
  # the Setting class, but we want to break depednencies that directly
  # point to canvas.
  def self.settings_store(safe_invoke = false)
    return @@settings_store if @@settings_store
    return nil if safe_invoke

    raise UnconfiguredError, "an object with an interface for loading settings must be specified as 'settings_store'"
  end

  class AuthenticationError < RuntimeError
    def response_status
      401
    end
  end

  class InvalidToken < AuthenticationError
  end

  class TokenExpired < AuthenticationError
  end

  class InvalidJwtKey < AuthenticationError
  end

  def self.encryption_key
    @encryption_key ||= begin
      res = config && config["encryption_key"]
      raise("encryption key required, see config/security.yml") unless res
      raise("encryption key is too short, see config/security.yml") unless res.to_s.length >= 20

      res.to_s
    end
  end

  def self.encryption_keys
    @encryption_keys ||= [encryption_key] + Array(config && config["previous_encryption_keys"]).map(&:to_s)
  end

  def self.config
    @config ||= begin
      path = Rails.root.join("config/security.yml")
      raise("config/security.yml missing, see security.yml.example") unless path.file?

      result = YAML.safe_load(ERB.new(path.read).result, aliases: true)[Rails.env]
      result["encryption_key"] ||= Rails.application.credentials.security_encryption_key
      result
    end
  end

  def self.encrypt_data(data)
    nonce = SecureRandom.bytes(12)
    encryptor = OpenSSL::Cipher.new("aes-256-gcm").encrypt
    encryptor.key = Digest::SHA1.hexdigest(encryption_key)[0...32]
    encryptor.iv = nonce
    encryptor.auth_data = "Canvas-v1.0.0"
    encrypted_data = encryptor.update(data) + encryptor.final
    tag = encryptor.auth_tag
    [encrypted_data, nonce, tag]
  end

  def self.decrypt_data(data, nonce, tag)
    decipher = OpenSSL::Cipher.new("aes-256-gcm").decrypt
    decipher.key = Digest::SHA1.hexdigest(encryption_key)[0...32]
    decipher.iv = nonce
    decipher.auth_tag = tag
    decipher.auth_data = "Canvas-v1.0.0"
    decipher.update(data) + decipher.final
  end

  def self.url_key_encrypt_data(data)
    encryption_data = encrypt_data("#{data.encoding}~#{data.dup.force_encoding("ASCII-8BIT")}")
    encryption_data.map { |item| Base64.urlsafe_encode64(item, padding: false) }.join("~")
  end

  def self.url_key_decrypt_data(data)
    encrypted_data, nonce, tag = data.split("~").map { |item| Base64.urlsafe_decode64(item) }
    encoding, data = decrypt_data(encrypted_data, nonce, tag).split("~", 2)
    data.force_encoding(encoding)
  end

  def self.encrypt_password(secret, key)
    require "base64"
    c = OpenSSL::Cipher.new("aes-256-cbc")
    c.encrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + encryption_key)[0...32]
    c.iv = iv = c.random_iv
    e = c.update(secret)
    e << c.final
    [Base64.encode64(e), Base64.encode64(iv)]
  end

  def self.decrypt_password(secret, salt, key, encryption_key = nil)
    require "base64"
    encryption_keys = Array(encryption_key) + self.encryption_keys
    last_error = nil
    encryption_keys.each do |single_encryption_key|
      c = OpenSSL::Cipher.new("aes-256-cbc")
      c.decrypt
      c.key = Digest::SHA1.hexdigest(key + "_" + single_encryption_key)[0...32]
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
      OpenSSL::Digest.new("sha1"), (encryption_key || self.encryption_key), str
    )
  end

  def self.hmac_sha512(str, encryption_key = nil)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha512"), (encryption_key || self.encryption_key), str
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

  def self.sign_hmac_sha512(string_to_sign, signing_secret = services_signing_secret)
    sign_hmac(string_to_sign, signing_secret, "sha512")
  end

  def self.verify_hmac_sha512(message, signature, signing_secret = services_signing_secret)
    verify_hmac(message, signature, signing_secret, "sha512")
  end

  def self.sign_hmac(string_to_sign, signing_secret = services_signing_secret, hashing_alg = "sha512")
    OpenSSL::HMAC.digest(hashing_alg, signing_secret, string_to_sign)
  end

  def self.verify_hmac(message, signature, signing_secret = services_signing_secret, hashing_alg = "sha512")
    secrets_to_check = [signing_secret]
    if signing_secret == services_signing_secret && services_previous_signing_secret
      secrets_to_check << services_previous_signing_secret
    end
    secrets_to_check.each do |cur_secret|
      comparison = sign_hmac(message, cur_secret, hashing_alg)
      return true if ActiveSupport::SecurityUtils.secure_compare(signature, comparison)
    end
    false
  end

  # Creates a JWT token string
  #
  # body (Hash) - The contents of the JWT token
  # expires (Time) - When the token should expire. `nil` for no expiration
  # key (String) - The key to sign with. `nil` will use the currently configured key
  # alg (Symbol) - The algorithm used to generate the signature. Should be `:HS512` or `:ES512`!
  #                To keep backwards compatibility, `nil` will default to `:HS256` for now.
  #
  # Returns the token as a string.
  def self.create_jwt(body, expires = nil, key = nil, alg = nil)
    jwt_body = body
    if expires
      jwt_body = jwt_body.merge({ exp: expires.to_i })
    end
    raw_jwt = JSON::JWT.new(jwt_body)
    return raw_jwt.to_s if key == :unsigned

    raw_jwt.sign(key || encryption_key, alg || :HS256).to_s
  end

  # Creates an encrypted JWT token string
  #
  # This is a token that will be used for identifying the user to
  # canvas on API calls and to other canvas-ecosystem services.
  #
  # payload (hash) - The data you want in the token
  # signing_secret (big string) - The shared secret for signing
  # encryption_secret (big string) - The shared key for symmetric key encryption.
  # alg (Symbol) - The algorithm used to generate the signature. Should be `:HS512` or `:ES512`!
  #                To keep backwards compatibility, `nil` will default to `:HS256` for now.
  #
  # Returns the token as a string.
  def self.create_encrypted_jwt(payload, signing_secret, encryption_secret, alg = nil)
    raise InvalidJwtKey unless signing_secret && encryption_secret

    jwt = JSON::JWT.new(payload)
    jws = jwt.sign(signing_secret, alg || :HS256)
    jwe = JSON::JWE.new(jws)
    jwe.alg = "dir"
    jwe.enc = "A256GCM"
    jwe.header[:region] = region if region
    jwe.header[:environment] = environment if environment
    jwe.encrypt!(encryption_secret)
    jwe.to_s
  end

  # Verifies and decodes a JWT token
  #
  # token (String) - The token to decode
  # keys (Array) - An array of keys to use verifying. Will be added to the current
  #                set of keys
  #
  # Returns the token body as a Hash if it's valid.
  #
  # Raises CanvasSecurity::TokenExpired if the token has expired, and
  # CanvasSecurity::InvalidToken if the token is otherwise invalid.
  def self.decode_jwt(token, keys = [], ignore_expiration: false)
    keys += encryption_keys

    keys.each do |key|
      body = JSON::JWT.decode(token, key)
      verify_jwt(body, ignore_expiration:)
      return body.with_indifferent_access
    rescue JSON::JWS::VerificationFailed
      # Keep looping, to try all the keys. If none succeed,
      # we raise below.
    rescue CanvasSecurity::TokenExpired
      raise
    rescue => e
      raise CanvasSecurity::InvalidToken, e
    end

    raise CanvasSecurity::InvalidToken
  end

  def self.decrypt_encrypted_jwt(token, signing_secret, encryption_secret, ignore_expiration: false)
    begin
      signed_coded_jwt = JSON::JWT.decode(token, encryption_secret)
    rescue JSON::JWE::DecryptionFailed => e
      # this seems to happen if the token is of a valid shape,
      # but signed by some OTHER encryption secret?
      CanvasErrors.capture_exception(:security_auth, e, :warn)
      raise CanvasSecurity::InvalidToken
    end

    secrets_to_check = if signing_secret.is_a?(Hash)
                         Array.wrap(signing_secret[JSON::JWT.decode(signed_coded_jwt.plain_text, :skip_verification).header["alg"]])
                       else
                         Array.wrap(signing_secret)
                       end

    secrets_to_check.each do |cur_secret|
      raw_jwt = JSON::JWT.decode(signed_coded_jwt.plain_text, cur_secret)
      verify_jwt(raw_jwt, ignore_expiration:)
      return raw_jwt.with_indifferent_access
    rescue JSON::JWS::VerificationFailed => e
      CanvasErrors.capture_exception(:security_auth, e, :info)
    end
    raise CanvasSecurity::InvalidToken
  end

  def self.base64_encode(token_string)
    Base64.encode64(token_string).encode("utf-8").delete("\n")
  end

  def self.base64_decode(token_string)
    utf8_string = token_string.dup.force_encoding(Encoding::UTF_8)
    Base64.decode64(utf8_string.encode("ascii-8bit"))
  end

  def self.validate_encryption_key(overwrite = false)
    db_hash = settings_store.get("encryption_key_hash", nil) rescue return # in places like rake db:test:reset, we don't care that the db/table doesn't exist
    return if encryption_keys.any? { |key| Digest::SHA1.hexdigest(key) == db_hash }

    if db_hash.nil? || overwrite
      begin
        settings_store.set("encryption_key_hash", Digest::SHA1.hexdigest(encryption_key))
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
        # the db may not exist yet
      end
    else
      abort "encryption key is incorrect. if you have intentionally changed it, you may want to run `rake db:reset_encryption_key_hash`"
    end
  end

  class << self
    def services_encryption_secret
      Rails.application&.credentials&.dig(:canvas_security, :encryption_secret)
    end

    def services_signing_secret
      Rails.application&.credentials&.dig(:canvas_security, :signing_secret)
    end

    def services_previous_signing_secret
      Rails.application&.credentials&.dig(:canvas_security, :signing_secret_deprecated)
    end

    private

    def verify_jwt(body, ignore_expiration: false)
      verification_time = Time.now.utc
      if body[:iat].present?
        iat = timestamp_as_integer(body[:iat])
        if iat > verification_time.to_i && iat < verification_time.to_i + 300
          verification_time = iat
        end
      end

      if body[:exp].present? &&
         !ignore_expiration &&
         timestamp_as_integer(body[:exp]) < verification_time.to_i
        raise CanvasSecurity::TokenExpired
      end

      if body[:nbf].present? &&
         timestamp_as_integer(body[:nbf]) > verification_time.to_i
        raise CanvasSecurity::InvalidToken
      end
    end

    def timestamp_as_integer(timestamp)
      timestamp.is_a?(Time) ? timestamp.to_i : timestamp
    end
  end
end
