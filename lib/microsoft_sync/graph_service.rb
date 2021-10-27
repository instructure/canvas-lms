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
# Client to access Microsoft's Graph API, used to administer groups and teams
# in the MicrosoftSync project (see app/models/microsoft_sync/group.rb). Make
# a new client with `GraphService.new(tenant_name)`
#
# This class is a lower-level interface, akin to what a Microsoft API gem which
# provide, which has no knowledge of Canvas models. So many operations will be
# used via GraphServiceHelpers, which does have knowledge of Canvas models.
#
module MicrosoftSync
  class GraphService
    DIRECTORY_OBJECT_PREFIX = 'https://graph.microsoft.com/v1.0/directoryObjects/'
    GROUP_USERS_BATCH_SIZE = 20

    attr_reader :http

    delegate :request, :expand_options, :get_paginated_list, :run_batch, :quote_value, to: :http

    def initialize(tenant, extra_statsd_tags)
      @http = MicrosoftSync::GraphService::Http.new(tenant, extra_statsd_tags)
    end

    # ENDPOINTS:

    # === Education Classes: ===

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_education_classes(options = {}, &blk)
      get_paginated_list(
        'education/classes',
        quota: [1, 0],
        special_cases: [
          SpecialCase.new(
            400, /Education_ObjectType.*does not exist as.*property/,
            result: Errors::NotEducationTenant
          )
        ],
        **options, &blk
      )
    end

    def create_education_class(params)
      request(:post, 'education/classes', quota: [1, 1], body: params)
    end

    # === Groups: ===

    def update_group(group_id, params)
      request(:patch, "groups/#{group_id}", quota: [1, 1], body: params)
    end

    # Used for debugging. Example:
    # get_group('id', select: %w[microsoft_EducationClassLmsExt microsoft_EducationClassSisExt])
    def get_group(group_id, options = {})
      request(:get, "groups/#{group_id}", quota: [1, 0], query: expand_options(**options))
    end

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_group_members(group_id, options = {}, &blk)
      get_paginated_list("groups/#{group_id}/members", quota: [3, 0], **options, &blk)
    end

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_group_owners(group_id, options = {}, &blk)
      get_paginated_list("groups/#{group_id}/owners", quota: [2, 0], **options, &blk)
    end

    BATCH_REMOVE_GROUP_USERS_SPECIAL_CASES = [
      SpecialCase.new(
        404, /does not exist or one of its queried reference-property objects are not present/i,
        result: :ignored
      ),
      SpecialCase.new(
        400, /One or more removed object references do not exist for the following modified/i,
        result: :ignored
      ),
      SpecialCase.new(
        400, /must have at least one owner, hence this owner cannot be removed/i,
        result: Errors::MissingOwners
      ),
    ].freeze

    # Returns nil if all removed, or a hash with a list of :members and/or :owners that did
    # not exist in the group (e.g. {owners: ['a', 'b'], members: ['c']} or {owners: ['a']}
    # NOTE: Microsoft API does not distinguish between a group not existing, a
    # user not existing, and an owner not existing in the group. If the group
    # doesn't exist, this will return the full lists of members and owners
    # passed in.
    def remove_group_users_ignore_missing(group_id, members: [], owners: [])
      check_group_users_args(members, owners)

      reqs =
        group_remove_user_requests(group_id, members, 'members') +
        group_remove_user_requests(group_id, owners, 'owners')
      quota = [reqs.count, reqs.count]

      ignored_request_ids = run_batch(
        'group_remove_users',
        reqs,
        quota: quota,
        special_cases: BATCH_REMOVE_GROUP_USERS_SPECIAL_CASES
      ).keys
      split_request_ids_to_hash(ignored_request_ids)
    end

    BATCH_ADD_USERS_TO_GROUP_SPECIAL_CASES = [
      SpecialCase.new(
        400, /One or more added object references already exist/i,
        result: :ignored
      ),
      SpecialCase.new(
        403, /would exceed the maximum quota count.*for forward-link.*owners/i,
        result: Errors::OwnersQuotaExceeded
      ),
      SpecialCase.new(
        403, /would exceed the maximum quota count.*for forward-link.*members/i,
        result: Errors::MembersQuotaExceeded
      ),
    ].freeze

    # Returns {owners: ['a', 'b', 'c'], members: ['d', 'e', 'f']} if there are owners
    # or members not added. If all were added successfully, returns nil.
    def add_users_to_group_via_batch(group_id, members, owners)
      reqs =
        group_add_user_requests(group_id, members, 'members') +
        group_add_user_requests(group_id, owners, 'owners')
      ignored_request_ids = run_batch(
        'group_add_users',
        reqs,
        quota: [reqs.count, reqs.count],
        special_cases: BATCH_ADD_USERS_TO_GROUP_SPECIAL_CASES
      ).keys
      split_request_ids_to_hash(ignored_request_ids)
    end

    ADD_USERS_TO_GROUP_SPECIAL_CASES = [
      SpecialCase.new(
        400, /One or more added object references already exist/i,
        result: :fallback_to_batch
      ),
      # If a group has 81 owners, and we try to add 20 owners, but some or all
      # of 20 owners are already in the group, Microsoft returns the "maximum
      # quota count" error instead of the above "object references already
      # exist" error -- even if adding only the non-duplicate users wouldn't
      # push the total number over the maximum (100). In that case, fallback to
      # batch requests, which do not have this problem.
      SpecialCase.new(
        403, /would exceed the maximum quota count.*for forward-link.*owners/i,
        result: :fallback_to_batch
      ),
      SpecialCase.new(
        403, /would exceed the maximum quota count.*for forward-link.*members/i,
        result: :fallback_to_batch
      ),
    ].freeze

    # Returns nil if all added, or a hash with a list of :members and/or :owners that already
    # existed in the group (e.g. {owners: ['a', 'b'], members: ['c']} or {owners: ['a']}
    def add_users_to_group_ignore_duplicates(group_id, members: [], owners: [])
      check_group_users_args(members, owners)

      body = {
        'members@odata.bind' => members.map { |m| DIRECTORY_OBJECT_PREFIX + m },
        'owners@odata.bind' => owners.map { |o| DIRECTORY_OBJECT_PREFIX + o }
      }.reject { |_k, users| users.empty? }

      # Irregular write cost of adding members, about users_added/3, according to Microsoft.
      write_quota = ((members.length + owners.length) / 3.0).ceil
      response = request(
        :patch, "groups/#{group_id}",
        body: body,
        quota: [1, write_quota],
        special_cases: ADD_USERS_TO_GROUP_SPECIAL_CASES
      )

      if response == :fallback_to_batch
        add_users_to_group_via_batch(group_id, members, owners)
      end
    end

    # Maps requests ids, e.g. ["members_a", "members_b", "owners_a"]
    # to a hash like {members: %w[a b], owners: %w[a]}
    def split_request_ids_to_hash(req_ids)
      return nil if req_ids.blank?

      req_ids
        .group_by { |id| id.split("_").first.to_sym }
        .transform_values { |ids| ids.map { |id| id.split("_").last } }
    end

    # === Teams ===

    TEAM_EXISTS_SPECIAL_CASES = [
      SpecialCase.new(404, result: :not_found)
    ].freeze

    def team_exists?(team_id)
      request(:get, "teams/#{team_id}", special_cases: TEAM_EXISTS_SPECIAL_CASES) != :not_found
    end

    CREATE_EDUCATION_CLASS_TEAM_SPECIAL_CASES = [
      SpecialCase.new(
        400, /have one or more owners in order to create a Team/i,
        result: MicrosoftSync::Errors::GroupHasNoOwners
      ),
      SpecialCase.new(
        409, /group is already provisioned/i,
        result: MicrosoftSync::Errors::TeamAlreadyExists
      )
    ].freeze

    def create_education_class_team(group_id)
      body = {
        "template@odata.bind" =>
          "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')",
        "group@odata.bind" =>
          "https://graph.microsoft.com/v1.0/groups(#{quote_value(group_id)})"
      }

      # Use special_cases exceptions so they use statsd "expected" counters
      request(:post, 'teams', body: body, special_cases: CREATE_EDUCATION_CLASS_TEAM_SPECIAL_CASES)
    end

    # === Users ===

    def list_users(options = {}, &blk)
      get_paginated_list('users', quota: [2, 0], **options, &blk)
    end

    # ==== Helpers for removing and adding in batch ===

    def check_group_users_args(members, owners)
      raise ArgumentError, 'Missing members/owners' if members.empty? && owners.empty?

      if (n_total_additions = members.length + owners.length) > GROUP_USERS_BATCH_SIZE
        raise ArgumentError, "Only #{GROUP_USERS_BATCH_SIZE} users can be batched at " \
                             "once. Got #{n_total_additions}."
      end
    end

    def group_add_user_requests(group_id, user_aad_ids, members_or_owners)
      user_aad_ids.map do |aad_id|
        {
          id: "#{members_or_owners}_#{aad_id}",
          url: "/groups/#{group_id}/#{members_or_owners}/$ref",
          method: 'POST',
          body: { "@odata.id": DIRECTORY_OBJECT_PREFIX + aad_id },
          headers: { 'Content-Type' => 'application/json' }
        }
      end
    end

    def group_remove_user_requests(group_id, user_aad_ids, members_or_owners)
      user_aad_ids.map do |aad_id|
        {
          id: "#{members_or_owners}_#{aad_id}",
          url: "/groups/#{group_id}/#{members_or_owners}/#{aad_id}/$ref",
          method: 'DELETE'
        }
      end
    end
  end
end
