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

module MicrosoftSync
  class GraphService
    class GroupsEndpoints < EndpointsBase
      DIRECTORY_OBJECT_PREFIX = "https://graph.microsoft.com/v1.0/directoryObjects/"
      USERS_BATCH_SIZE = 20

      def update(group_id, params)
        request(:patch, "groups/#{group_id}", quota: [1, 1], body: params)
      end

      # Yields (results, next_link) for each page, or returns first page of results if no block given.
      def list_members(group_id, options = {}, &)
        get_paginated_list("groups/#{group_id}/members", quota: [3, 0], **options, &)
      end

      # Yields (results, next_link) for each page, or returns first page of results if no block given.
      def list_owners(group_id, options = {}, &)
        get_paginated_list("groups/#{group_id}/owners", quota: [2, 0], **options, &)
      end

      BATCH_REMOVE_USERS_SPECIAL_CASES = [
        SpecialCase.new(
          404,
          /does not exist or one of its queried reference-property objects are not present/i,
          result: :ignored
        ),
        SpecialCase.new(
          400,
          /One or more removed object references do not exist for the following modified/i,
          result: :ignored
        ),
        SpecialCase.new(
          400,
          /must have at least one owner, hence this owner cannot be removed/i,
          result: Errors::MissingOwners
        ),
      ].freeze

      # Returns a GroupMembershipChangeResult
      # NOTE: Microsoft API does not distinguish between a group not existing, a
      # user not existing, and an owner not existing in the group. If the group
      # doesn't exist, all members and owners will be listed in the change result.
      def remove_users_ignore_missing(group_id, members: [], owners: [])
        check_group_users_args(members, owners)

        reqs =
          group_remove_user_requests(group_id, members, "members") +
          group_remove_user_requests(group_id, owners, "owners")
        quota = [reqs.count, reqs.count]

        ignored_request_hash = run_batch(
          "group_remove_users",
          reqs,
          quota:,
          special_cases: BATCH_REMOVE_USERS_SPECIAL_CASES
        )
        create_membership_change_result(ignored_request_hash)
      end

      BATCH_ADD_USERS_SPECIAL_CASES = [
        SpecialCase.new(
          400,
          /One or more added object references already exist/i,
          result: :already_in_group
        ),
        SpecialCase.new(
          403,
          /would exceed the maximum quota count.*for forward-link.*owners/i,
          result: Errors::OwnersQuotaExceeded
        ),
        SpecialCase.new(
          403,
          /would exceed the maximum quota count.*for forward-link.*members/i,
          result: Errors::MembersQuotaExceeded
        ),
        SpecialCase.new(404, result: GroupMembershipChangeResult::NONEXISTENT_USER) do |response|
          # Error message must have user id (see group_add_user_requests) to match.
          aad_id = response.batch_request_id.gsub(/^members_|^owners_/, "")
          regex = /#{Regexp.escape aad_id}.* does not exist or one of its queried reference/
          response.body =~ regex
        end,
      ].freeze

      # Returns a GroupMembershipChangeResult
      def add_users_via_batch(group_id, members, owners)
        reqs =
          group_add_user_requests(group_id, members, "members") +
          group_add_user_requests(group_id, owners, "owners")
        ignored_request_hash = run_batch(
          "group_add_users",
          reqs,
          quota: [reqs.count, reqs.count],
          special_cases: BATCH_ADD_USERS_SPECIAL_CASES
        )
        create_membership_change_result(ignored_request_hash)
      end

      ADD_USERS_SPECIAL_CASES = [
        SpecialCase.new(
          400,
          /One or more added object references already exist/i,
          result: :fallback_to_batch
        ),
        # If a group has 81 owners, and we try to add 20 owners, but some or all
        # of 20 owners are already in the group, Microsoft returns the "maximum
        # quota count" error instead of the above "object references already
        # exist" error -- even if adding only the non-duplicate users wouldn't
        # push the total number over the maximum (100). In that case, fallback to
        # batch requests, which do not have this problem.
        SpecialCase.new(
          403,
          /would exceed the maximum quota count.*for forward-link.*(owners|members)/i,
          result: :fallback_to_batch
        ),
        # There is one additional dynamic special case in add_users_special_cases()
      ].freeze

      # Returns nil or a blank GroupMembershipChangeResult if all users were
      # added successfully. Returns a GroupMembershipChangeResult batch to
      # return if there are any non-fatal issues (e.g. some users existed in
      # the group already)
      def add_users_ignore_duplicates(group_id, members: [], owners: [])
        check_group_users_args(members, owners)

        body = {
          "members@odata.bind" => members.map { |m| DIRECTORY_OBJECT_PREFIX + m },
          "owners@odata.bind" => owners.map { |o| DIRECTORY_OBJECT_PREFIX + o }
        }.reject { |_k, users| users.empty? }

        # Irregular write cost of adding members, about users_added/3, according to Microsoft.
        write_quota = ((members.length + owners.length) / 3.0).ceil
        response = request(
          :patch,
          "groups/#{group_id}",
          body:,
          quota: [1, write_quota],
          special_cases: add_users_special_cases(group_id)
        )

        if response == :fallback_to_batch
          add_users_via_batch(group_id, members, owners)
        end
      end

      private

      def add_users_special_cases(group_id)
        ADD_USERS_SPECIAL_CASES + [
          SpecialCase.new(
            404,
            /does not exist or one of its queried reference/,
            result: Errors::GroupNotFound
          ) { |response| response.body.include?(group_id) },
          # 404 referencing some ID which is NOT the group ID. Probably one of
          # the user(s) don't exist. Fallback to batch to deal with each user
          # separately, in case multiple do not exist.
          SpecialCase.new(
            404, /does not exist or one of its queried reference/, result: :fallback_to_batch
          )
        ]
      end

      # ==== Helpers for removing and adding in batch ===

      # Expects a hash like {"members_1234" => :ignored, "owners_89ab" => :ignored}
      def create_membership_change_result(batch_result_hash)
        res = GroupMembershipChangeResult.new

        batch_result_hash.each do |request_id, special_case_value|
          members_or_owners, user_id = request_id.split("_")
          res.add_issue(members_or_owners, user_id, special_case_value)
        end

        res
      end

      def check_group_users_args(members, owners)
        raise ArgumentError, "Missing members/owners" if members.empty? && owners.empty?

        if (n_total_additions = members.length + owners.length) > USERS_BATCH_SIZE
          raise ArgumentError, "Only #{USERS_BATCH_SIZE} users can be batched at " \
                               "once. Got #{n_total_additions}."
        end
      end

      def group_add_user_requests(group_id, user_aad_ids, members_or_owners)
        user_aad_ids.map do |aad_id|
          {
            id: "#{members_or_owners}_#{aad_id}",
            url: "/groups/#{group_id}/#{members_or_owners}/$ref",
            method: "POST",
            body: { "@odata.id": DIRECTORY_OBJECT_PREFIX + aad_id },
            headers: { "Content-Type" => "application/json" }
          }
        end
      end

      def group_remove_user_requests(group_id, user_aad_ids, members_or_owners)
        user_aad_ids.map do |aad_id|
          {
            id: "#{members_or_owners}_#{aad_id}",
            url: "/groups/#{group_id}/#{members_or_owners}/#{aad_id}/$ref",
            method: "DELETE"
          }
        end
      end
    end
  end
end
