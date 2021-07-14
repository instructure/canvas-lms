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

#
# Is responsible for finding the the user's ULUVs (user lookup values -- the value
# we use to look up a Micrososft user by) according to the
# microsoft_sync_login_attribute in the Account settings
#
module MicrosoftSync
  # When `login_attribute` is not set or is one that we don't know how find the
  # Canvas user id information, we'll raise and exception and stop the job
  class InvalidOrMissingLoginAttributeConfig < StandardError
    include Errors::GracefulCancelErrorMixin
  end

  class UsersUluvsFinder
    attr_reader :user_ids, :root_account

    delegate :settings, to: :root_account

    def initialize(user_ids, root_account)
      @user_ids = user_ids
      @root_account = root_account
    end

    def call
      return [] if user_ids.blank? || root_account.blank?

      case login_attribute
      when 'email' then find_by_email
      when 'preferred_username' then find_by_preferred_username
      when 'sis_user_id' then find_by_sis_user_id
      else raise InvalidOrMissingLoginAttributeConfig
      end
    end

    private

    def find_by_email
      users_uluvs = CommunicationChannel
        .where(user_id: user_ids, path_type: 'email', workflow_state: 'active')
        .order(position: :asc)
        .pluck(:user_id, :path)

      uniq_uluv_by_user_id(users_uluvs)
    end

    def find_by_preferred_username
      users_uluvs = find_active_pseudonyms.pluck(:user_id, :unique_id)

      uniq_uluv_by_user_id(users_uluvs)
    end

    def find_by_sis_user_id
      users_uluvs = find_active_pseudonyms.pluck(:user_id, :sis_user_id)

      uniq_uluv_by_user_id(users_uluvs)
    end

    def find_active_pseudonyms
      root_account.pseudonyms.active.where(user_id: user_ids).order(position: :asc)
    end

    def login_attribute
      @login_attribute ||= begin
        enabled = settings[:microsoft_sync_enabled]
        login_attribute = settings[:microsoft_sync_login_attribute]

        raise InvalidOrMissingLoginAttributeConfig unless enabled && login_attribute

        login_attribute
      end
    end

    # The user can have more than one communication channel/pseudonym, so we're
    # ordering the users_uluvs by position ASC (the highest position is the
    # smallest number) and returning the first uluv found to the related user_id.
    def uniq_uluv_by_user_id(users_uluvs)
      return [] unless users_uluvs

      response = {}

      users_uluvs.each { |user_id, uluv| response[user_id] ||= uluv }

      response.to_a
    end
  end
end
