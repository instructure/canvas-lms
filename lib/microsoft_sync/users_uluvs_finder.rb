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
# we use to look up a Microsoft user by) according to the
# microsoft_sync_login_attribute in the Account settings
#
module MicrosoftSync
  # When `login_attribute` is not set or is one that we don't know how find the
  # Canvas user id information, we'll raise and exception and stop the job
  class InvalidOrMissingLoginAttributeConfig < Errors::GracefulCancelError
    def self.public_message
      I18n.t 'Invalid or missing "login attribute" config in account'
    end
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

      users_uluvs =
        case login_attribute
        when "email" then find_by_email
        when "preferred_username" then find_by_active_pseudonyms_field(:unique_id)
        when "sis_user_id" then find_by_active_pseudonyms_field(:sis_user_id)
        when "integration_id" then find_by_active_pseudonyms_field(:integration_id)
        else raise InvalidOrMissingLoginAttributeConfig
        end

      # The user can have more than one communication channel/pseudonym, so we're
      # ordering the users_uluvs by position ASC (the highest position is the
      # smallest number) and returning the first uluv found to the related user_id.
      users_uluvs
        .uniq(&:first)
        .map { |user_id, uluv| [user_id, uluv + login_attribute_suffix] }
    end

    private

    def find_by_email_local(local_user_ids)
      CommunicationChannel
        .where(user_id: local_user_ids, path_type: "email", workflow_state: "active")
        .order(position: :asc)
        .pluck(:user_id, :path)
    end

    # Looks for for CommunicationChannels on the each user's home shard.
    def find_by_email
      sync_shard = Shard.current
      user_ids.group_by { |uid| Shard.shard_for(uid) }.flat_map do |look_on_shard, uids|
        ids_relative_to_look_on_shard = uids.map do |uid|
          Shard.relative_id_for(uid, sync_shard, look_on_shard)
        end

        look_on_shard.activate do
          find_by_email_local(ids_relative_to_look_on_shard)
        end.map do |uid, path|
          [Shard.relative_id_for(uid, look_on_shard, sync_shard), path]
        end
      end
    end

    # Retrieves Pseudonyms for the given user_ids that have
    # the given field defined. Searches the current shard for
    # all user_ids first, then any cross-shard users. Prefers
    # pseudonyms from the given root account.
    # Returns an array of [user id, value for field]
    def find_by_active_pseudonyms_field(field)
      local_results = find_by_active_pseudonyms_field_local(field, user_ids)
      found_user_ids = local_results.map(&:user_id).uniq
      missing_user_ids = user_ids.difference(found_user_ids)

      # look on other present shards, and only for users that live on that shard
      sync_shard = Shard.current
      other_results = Shard.partition_by_shard(missing_user_ids) do |shard_user_ids|
        next if Shard.current == sync_shard

        find_by_active_pseudonyms_field_local(field, shard_user_ids)
      end

      # prefer the current shard
      (local_results + other_results)
        # prefer the current root account
        .sort_by { |ps| (ps.root_account_id == root_account.id) ? 0 : 1 }
        .map { |ps| [ps.user_id, ps[field]] }
    end

    def find_by_active_pseudonyms_field_local(field, uids)
      Pseudonym
        .active
        .where(user_id: uids)
        .where.not(field => nil)
        .order(position: :asc)
        .select(:user_id, field, :root_account_id)
    end

    def login_attribute
      enabled = settings[:microsoft_sync_enabled]
      login_attribute = settings[:microsoft_sync_login_attribute]

      raise InvalidOrMissingLoginAttributeConfig unless enabled && login_attribute

      login_attribute
    end

    def login_attribute_suffix
      @login_attribute_suffix ||= settings[:microsoft_sync_login_attribute_suffix] || ""
    end
  end
end
