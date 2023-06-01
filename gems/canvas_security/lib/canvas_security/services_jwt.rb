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

class CanvasSecurity::ServicesJwt
  KeyStorage = CanvasSecurity::KeyStorage.new("services-jwt")

  class InvalidRefresh < RuntimeError; end

  REFRESH_WINDOW = 6.hours

  attr_reader :token_string, :is_wrapped

  def initialize(raw_token_string, wrapped = true)
    @is_wrapped = wrapped
    if raw_token_string.nil?
      raise ArgumentError, "Cannot decode nil token string"
    end

    @token_string = raw_token_string
  end

  def wrapper_token
    return {} unless is_wrapped

    raw_wrapper_token = CanvasSecurity.base64_decode(token_string)
    keys = [signing_secret]
    keys << previous_signing_secret if previous_signing_secret
    CanvasSecurity.decode_jwt(raw_wrapper_token, keys)
  end

  def original_token(ignore_expiration: false)
    original_crypted_token = if is_wrapped
                               wrapper_token[:user_token]
                             else
                               CanvasSecurity.base64_decode(token_string)
                             end
    CanvasSecurity::ServicesJwt.decrypt(
      original_crypted_token,
      ignore_expiration:
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

  # Symmetric services JWTs are now deprecated
  def self.generate(payload_data, base64 = true, symmetric: false)
    payload = create_payload(payload_data)
    crypted_token = if symmetric
                      CanvasSecurity.create_encrypted_jwt(payload, signing_secret, encryption_secret)
                    else
                      CanvasSecurity.create_encrypted_jwt(
                        payload,
                        CanvasSecurity::ServicesJwt::KeyStorage.present_key,
                        encryption_secret,
                        :autodetect
                      )
                    end
    return crypted_token unless base64

    CanvasSecurity.base64_encode(crypted_token)
  end

  def self.for_user(domain, user, real_user: nil, workflows: nil, context: nil, symmetric: false)
    if domain.blank? || user.nil?
      raise ArgumentError, "Must have a domain and a user to build a JWT"
    end

    payload = {
      sub: user.global_id,
      domain:
    }
    payload[:masq_sub] = real_user.global_id if real_user
    if workflows.present?
      payload[:workflows] = workflows
      state = CanvasSecurity::JWTWorkflow.state_for(workflows, context, user)
      payload[:workflow_state] = state unless state.empty?
    end
    if context
      payload[:context_type] = context.class.name
      payload[:context_id] = context.id.to_s
    end
    generate(payload, symmetric:)
  end

  def self.refresh_for_user(jwt, domain, user, real_user: nil, symmetric: false)
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

    for_user(domain,
             user,
             real_user:,
             workflows: payload[:workflows],
             context:,
             symmetric:)
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

  def self.decrypt(token, ignore_expiration: false)
    CanvasSecurity.decrypt_encrypted_jwt(token,
                                         {
                                           "HS256" => [signing_secret, previous_signing_secret],
                                           "RS256" => KeyStorage.public_keyset
                                         },
                                         encryption_secret,
                                         ignore_expiration:)
  end

  def self.encryption_secret
    CanvasSecurity.services_encryption_secret
  end

  def self.signing_secret
    CanvasSecurity.services_signing_secret
  end

  def self.previous_signing_secret
    CanvasSecurity.services_previous_signing_secret
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
      invalid_real = if payload[:masq_sub].present?
                       real_user.nil? || payload[:masq_sub] != real_user.global_id
                     else
                       real_user.present?
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
