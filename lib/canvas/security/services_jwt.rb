# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class Canvas::Security::ServicesJwt
  class InvalidRefresh < RuntimeError; end

  REFRESH_WINDOW = 6.hours

  attr_reader :token_string, :is_wrapped

  def initialize(raw_token_string, wrapped=true)
    @is_wrapped = wrapped
    if raw_token_string.nil?
      raise ArgumentError, "Cannot decode nil token string"
    end
    @token_string = raw_token_string
  end

  def wrapper_token
    return {} unless is_wrapped
    raw_wrapper_token = Canvas::Security.base64_decode(token_string)
    keys = [signing_secret]
    keys << previous_signing_secret if previous_signing_secret
    Canvas::Security.decode_jwt(raw_wrapper_token, keys)
  end

  def original_token(ignore_expiration: false)
    original_crypted_token = if is_wrapped
      wrapper_token[:user_token]
    else
      Canvas::Security.base64_decode(token_string)
    end
    Canvas::Security.decrypt_services_jwt(
      original_crypted_token,
      signing_secret,
      encryption_secret,
      ignore_expiration: ignore_expiration
    )
  rescue Canvas::Security::InvalidToken
    # if we failed during the wrapper token decoding then
    # there is no way to decrypt this because we already
    # tried the relevent keys, so we need not try anything else
    # if original_crypted_token is nil.
    raise unless original_crypted_token && previous_signing_secret
    Canvas::Security.decrypt_services_jwt(
      original_crypted_token,
      previous_signing_secret,
      encryption_secret,
      ignore_expiration: ignore_expiration
    )
  end

  def id
    original_token[:jti]
  end

  def user_global_id
    original_token[:sub]
  end

  def masquerading_user_global_id
    original_token[:masq_sub]
  end

  def expires_at
    original_token[:exp]
  end

  def self.generate(payload_data, base64=true)
    payload = create_payload(payload_data)
    crypted_token = Canvas::Security.create_encrypted_jwt(payload, signing_secret, encryption_secret)
    return crypted_token unless base64
    Canvas::Security.base64_encode(crypted_token)
  end

  def self.for_user(domain, user, real_user: nil, workflows: nil, context: nil)
    if domain.blank? || user.nil?
      raise ArgumentError, "Must have a domain and a user to build a JWT"
    end

    payload = {
      sub: user.global_id,
      domain: domain
    }
    payload[:masq_sub] = real_user.global_id if real_user
    if workflows.present?
      payload[:workflows] = workflows
      state = Canvas::JWTWorkflow.state_for(workflows, context, user)
      payload[:workflow_state] = state unless state.empty?
    end
    if context
      payload[:context_type] = context.class.name
      payload[:context_id] = context.id.to_s
    end
    generate(payload)
  end

  def self.refresh_for_user(jwt, domain, user, real_user: nil)
    begin
      payload = new(jwt, false).original_token(ignore_expiration: true)
    rescue JSON::JWT::InvalidFormat
      raise InvalidRefresh, "invalid token"
    end

    if refresh_invalid_for_user?(payload, domain, user, real_user)
      raise InvalidRefresh, "token does not match user and domain"
    end

    if past_refresh_window?(payload[:exp])
      raise InvalidRefresh, "refresh window exceeded"
    end

    if payload[:context_type].present?
      context = payload[:context_type].constantize.find(payload[:context_id])
    end

    for_user(domain, user,
      real_user: real_user,
      workflows: payload[:workflows],
      context: context)
  end


  def self.create_payload(payload_data)
    if payload_data[:sub].nil?
      raise ArgumentError, "Cannot generate a services JWT without a 'sub' entry"
    end
    timestamp = Time.zone.now.to_i
    payload_data.merge({
      iss: "Canvas",
      aud: ["Instructure"],
      exp: timestamp + 3600,  # token is good for 1 hour
      nbf: timestamp - 30,    # don't accept the token in the past
      iat: timestamp,         # tell when the token was issued
      jti: SecureRandom.uuid, # unique identifier
    })
  end

  def self.encryption_secret
    Canvas::Security.services_encryption_secret
  end

  def self.signing_secret
    Canvas::Security.services_signing_secret
  end

  def self.previous_signing_secret
    Canvas::Security.services_previous_signing_secret
  end

  private

  def encryption_secret
    self.class.encryption_secret
  end

  def signing_secret
    self.class.signing_secret
  end

  def previous_signing_secret
    self.class.previous_signing_secret
  end

  class << self
    private

    def refresh_invalid_for_user?(payload, domain, user, real_user)
      invalid_user = payload[:sub] != user.global_id
      invalid_domain = payload[:domain] != domain
      if payload[:masq_sub].present?
        invalid_real = real_user.nil? || payload[:masq_sub] != real_user.global_id
      else
        invalid_real = real_user.present?
      end
      invalid_user || invalid_domain || invalid_real
    end

    def past_refresh_window?(exp)
      if exp.is_a?(Time)
        refresh_exp = exp + REFRESH_WINDOW
        now = Time.zone.now
      else
        refresh_exp = exp + REFRESH_WINDOW.to_i
        now = Time.zone.now.to_i
      end
      refresh_exp <= now
    end
  end
end
