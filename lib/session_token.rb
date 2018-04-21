#
# Copyright (C) 2017 - present Instructure, Inc.
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

class SessionToken
  attr_accessor :pseudonym_id, :created_at, :signature, :current_user_id, :used_remember_me_token

  def initialize(pseudonym_id, current_user_id: nil, used_remember_me_token: nil)
    self.created_at = Time.now.utc
    self.pseudonym_id = pseudonym_id
    self.current_user_id = current_user_id
    self.used_remember_me_token = used_remember_me_token
    self.signature = Canvas::Security.hmac_sha1(signature_string)
  end

  def self.parse(serialized_token)
    # deserialize and validate structure
    result = JSONToken.decode(serialized_token) rescue nil
    return nil unless
      result.is_a?(Hash) &&
      result.keys.sort == ['created_at', 'current_user_id', 'pseudonym_id', 'signature', 'used_remember_me_token'] &&
      result['created_at'].is_a?(Integer) &&
      result['pseudonym_id'].is_a?(Integer) &&
      (result['current_user_id'].nil? || result['current_user_id'].is_a?(Integer)) &&
      [nil, true, false].include?(result['used_remember_me_token']) &&
      result['signature'].is_a?(String)

    # reconstruct token (validation of values for created_at and signature will
    # take place later)
    token = new(result['pseudonym_id'],
                current_user_id: result['current_user_id'],
                used_remember_me_token: result['used_remember_me_token'])
    token.created_at = Time.at(result['created_at'])
    token.signature = result['signature']
    return token
  end

  VALIDITY_PERIOD = 30

  def valid?
    now = Time.now.utc
    created_at >= now - VALIDITY_PERIOD.seconds &&
      created_at <= now + VALIDITY_PERIOD.seconds &&
      Canvas::Security.verify_hmac_sha1(signature, signature_string) rescue false
  end

  def as_json
    {
      created_at: created_at.to_i,
      pseudonym_id: pseudonym_id.to_i,
      current_user_id: current_user_id&.to_i,
      used_remember_me_token: used_remember_me_token.nil? ? nil : !!used_remember_me_token,
      signature: signature.to_s
    }
  end

  def to_s
    JSONToken.encode(as_json)
  end

  def signature_string
    [created_at.to_i.to_s,
     pseudonym_id.to_s,
     current_user_id.to_s,
     used_remember_me_token.to_s].join('::')
  end
end
