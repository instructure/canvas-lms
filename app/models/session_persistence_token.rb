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

require 'authlogic/crypto_providers/bcrypt'

# A SessionPersistenceToken is a one-time-use "remember me" token to maintain a
# user's login across browser sessions. It has an expiry, and it's destroyed
# when the user logs out, but most importantly, it is destroyed after the first
# time it is used to authenticate the user.
#
# The token is comprised of three fields:
# <token_id:pseudonym.persistence_token:random_uuid>
#
# The first field allows efficient lookup, the second field verifies that the
# pseudonym hasn't changed their password or anything else that changes the
# persistence_token, and the last field is an unguessable token identifier
# generated at random. This last field is password-equivalent, so it's stored
# as a salt+hash server-side.
#
# much of the theory here is based on this blog post:
# http://fishbowl.pastiche.org/2004/01/19/persistent_login_cookie_best_practice/
#
# See the PseudonymSession model for the *_cookie methods that use this class.
class SessionPersistenceToken < ActiveRecord::Base
  belongs_to :pseudonym

  attr_accessible :pseudonym, :crypted_token, :token_salt, :uncrypted_token
  attr_accessor :uncrypted_token
  validates_presence_of :pseudonym_id, :crypted_token, :token_salt

  def self.generate(pseudonym)
    salt = SecureRandom.hex(8)
    token = SecureRandom.hex(32)
    pseudonym.session_persistence_tokens.create!(
                 :token_salt => salt,
                 :uncrypted_token => token,
                 :crypted_token => self.hashed_token(salt, token))
  end

  def self.hashed_token(salt, token)
    self.crypto.encrypt(salt, token)
  end

  def self.crypto
    Authlogic::CryptoProviders::BCrypt
  end

  def self.find_by_pseudonym_credentials(creds)
    token_id, persistence_token, uuid = creds.split("::")
    return unless token_id.present? && persistence_token.present? && uuid.present?
    token = self.where(id: token_id).first
    return unless token
    return unless token.valid_token?(persistence_token, uuid)
    return token
  end

  def valid_token?(persistence_token, uncrypted_token)
    # if the pseudonym is marked deleted, the token can still be marked as
    # valid, but the actual login step will fail as expected.
    self.pseudonym &&
      self.pseudonym.persistence_token == persistence_token &&
      self.class.crypto.matches?(self.crypted_token, self.token_salt, uncrypted_token)
  end

  def pseudonym_credentials
    raise "can't build pseudonym_credentials except on just-generated token" unless uncrypted_token
    "#{id}::#{pseudonym.persistence_token}::#{uncrypted_token}"
  end

  def use!
    destroy
    return pseudonym
  end
end
