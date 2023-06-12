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

module AuthenticationMethods
  # this module bridges the gap between the token
  # defined in the canvas_security gem and the
  # canvas domain itself (users, pseudonyms, accounts, etc)
  module InstAccessToken
    # given a POTENTIAL token string, this will validate
    # it as being an InstAccess token and return
    # the token ruby object.
    #
    # A 'false' indicates this is not a token at all and we can skip
    # any other attempts at token processing.
    #
    # an error (AccessTokenError) means that this IS an inst access token, but
    # not a valid one (expired or bad signature) and processing should only
    # continue on the assumption that this is an invalid request.
    def self.parse(token_string)
      return false unless InstAccess::Token.token?(token_string)

      begin
        InstAccess::Token.from_token_string(token_string)
      rescue InstAccess::InvalidToken, # token didn't pass signature verification
             InstAccess::TokenExpired # token passed signature verification, but is expired
        raise AccessTokenError
      rescue InstAccess::ConfigError => e
        # InstAccess isn't configured. A human should fix that, but this method
        # should recover gracefully.
        Canvas::Errors.capture_exception(:inst_access, e, :warn)
        false
      end
    end

    # functionally encapsulates mapping an InstAccess token and a domain root account
    # to a user/pseudonym.  This is out on it's own because there are some db-state
    # edge cases (like multiple users with the same UUID due to user merges, etc)
    # that are convenient to test close to the implementation.
    #
    # the hash this method returns is defined up front with the intention
    # that the masquerading keys will only have their values populated if the token contains these values
    def self.load_user_and_pseudonym_context(token, domain_root_account)
      auth_context = {
        current_user: nil,
        current_pseudonym: nil,
        real_current_user: nil,
        real_current_pseudonym: nil
      }
      auth_context[:current_user] = find_user_by_uuid_prefer_local(token.user_uuid)
      return auth_context unless auth_context[:current_user]

      auth_context[:current_pseudonym] = SisPseudonym.for(
        auth_context[:current_user], domain_root_account, type: :implicit, require_sis: false
      )
      return auth_context unless auth_context[:current_pseudonym]

      if token.masquerading_user_uuid && token.masquerading_user_shard_id
        Shard.lookup(token.masquerading_user_shard_id).activate do
          real_user = find_user_by_uuid_prefer_local(token.masquerading_user_uuid)
          raise AccessTokenError, "masquerading user not found" unless real_user

          auth_context[:real_current_user] = real_user
          auth_context[:real_current_pseudonym] = SisPseudonym.for(
            real_user, domain_root_account, type: :implicit, require_sis: false
          )
        end
      end
      auth_context
    end

    # generally users should not share uuids.
    # this is just to make sure that when a shadow
    # user or similar exists, the local user
    # gets preferred.
    def self.find_user_by_uuid_prefer_local(uuid)
      User.active.where(uuid:).order(:id).first
    end
    private_class_method :find_user_by_uuid_prefer_local
  end
end
