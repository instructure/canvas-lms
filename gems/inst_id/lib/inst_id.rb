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

require 'active_support'
require 'json/jwt'
require 'inst_id/errors'
require 'inst_id/config'

class InstID
  ISSUER = "instructure:inst_id".freeze
  ENCRYPTION_ALGO = :'RSA-OAEP'
  ENCRYPTION_METHOD = :'A128CBC-HS256'

  attr_reader :jwt_payload

  def initialize(jwt_payload)
    @jwt_payload = jwt_payload.symbolize_keys
  end

  def user_uuid
    jwt_payload[:sub]
  end

  def canvas_domain
    jwt_payload[:canvas_domain]
  end

  def masquerading_user_uuid
    jwt_payload[:masq_sub]
  end

  def masquerading_user_shard_id
    jwt_payload[:masq_shard]
  end

  def to_token
    jwe = to_jws.encrypt(self.class.config.encryption_key, ENCRYPTION_ALGO, ENCRYPTION_METHOD)
    jwe.to_s
  end

  # only for testing purposes, or to do local dev w/o running a decrypting
  # service.  unencrypted tokens should not be released into the wild!
  def to_unencrypted_token
    to_jws.to_s
  end

  private

  def to_jws
    key = self.class.config.signing_key
    raise ConfigError, "Private signing key needed to produce tokens" unless key.private?

    jwt = JSON::JWT.new(jwt_payload)
    jwt.sign(key)
  end

  class << self
    private :new

    def for_user(user_uuid, canvas_domain: nil, real_user_uuid: nil, real_user_shard_id: nil)
      if user_uuid.blank?
        raise ArgumentError, "Must provide user uuid"
      end

      now = Time.now.to_i
      payload = {
        iss: ISSUER,
        iat: now,
        exp: now + 1.hour.to_i,
        sub: user_uuid,
      }
      payload[:canvas_domain] = canvas_domain if canvas_domain
      payload[:masq_sub] = real_user_uuid if real_user_uuid
      payload[:masq_shard] = real_user_shard_id if real_user_shard_id

      new(payload)
    end

    # Takes an unencrypted (but signed) token string
    def from_token(jws)
      sig_key = config.signing_key
      jwt = begin
              JSON::JWT.decode(jws, sig_key)
            rescue => e
              raise InvalidToken, e
            end
      raise TokenExpired if jwt[:exp] < Time.now.to_i

      new(jwt.to_hash)
    end

    def is_inst_id?(string)
      jwt = JSON::JWT.decode(string, :skip_verification)
      jwt[:iss] == ISSUER
    rescue
      false
    end

    # signing_key is required.  if you are going to be producing (and therefore
    # signing) tokens, this needs to be an RSA private key.  if you're just
    # consuming tokens, it can be the RSA public key corresponding to the
    # private key that signed them.
    # encryption_key is only required if you are going to be producing tokens.
    def configure(signing_key:, encryption_key: nil)
      @config = Config.new(signing_key, encryption_key)
    end

    # set a configuration only for the duration of the given block, then revert
    # it.  useful for testing.
    def with_config(signing_key:, encryption_key: nil)
      old_config = @config
      configure(signing_key: signing_key, encryption_key: encryption_key)
      yield
    ensure
      @config = old_config
    end

    def config
      @config || raise(ConfigError, "InstID is not configured!")
    end
  end
end
