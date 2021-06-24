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

    def initialize(tenant)
      @http = GraphServiceHttp.new(tenant)
    end

    # ENDPOINTS:

    # === Education Classes: ===

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_education_classes(options={}, &blk)
      get_paginated_list('education/classes', options, &blk)
    end

    def create_education_class(params)
      request(:post, 'education/classes', body: params)
    end

    # === Groups: ===

    def update_group(group_id, params)
      request(:patch, "groups/#{group_id}", body: params)
    end

    def add_users_to_group(group_id, members: [], owners: [])
      check_group_users_args(members, owners)

      body = {}
      unless members.empty?
        body['members@odata.bind'] = members.map{|m| DIRECTORY_OBJECT_PREFIX + m}
      end
      unless owners.empty?
        body['owners@odata.bind'] = owners.map{|o| DIRECTORY_OBJECT_PREFIX + o}
      end

      update_group(group_id, body)
    end

    # Used for debugging. Example:
    # get_group('id', select: %w[microsoft_EducationClassLmsExt microsoft_EducationClassSisExt])
    def get_group(group_id, options={})
      request(:get, "groups/#{group_id}", query: expand_options(**options))
    end

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_group_members(group_id, options={}, &blk)
      get_paginated_list("groups/#{group_id}/members", options, &blk)
    end

    # Yields (results, next_link) for each page, or returns first page of results if no block given.
    def list_group_owners(group_id, options={}, &blk)
      get_paginated_list("groups/#{group_id}/owners", options, &blk)
    end

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
      failed_req_ids = run_batch('group_remove_users', reqs) do |resp|
        (
          resp['status'] == 404 && resp['body'].to_s =~
            /does not exist or one of its queried reference-property objects are not present/i
        ) || (
          # This variant seems to happen right after removing a user with the UI
          resp['status'] == 400 && resp['body'].to_s =~
            /One or more removed object references do not exist for the following modified/i
        )
      end
      split_request_ids_to_hash(failed_req_ids)
    end

    # Returns {owners: ['a', 'b', 'c'], members: ['d', 'e', 'f']} if there are owners
    # or members not added. If all were added successfully, returns nil.
    def add_users_to_group_via_batch(group_id, members, owners)
      reqs =
        group_add_user_requests(group_id, members, 'members') +
        group_add_user_requests(group_id, owners, 'owners')
      failed_req_ids = run_batch('group_add_users', reqs) do |r|
        r['status'] == 400 && r['body'].to_s =~ /One or more added object references already exist/i
      end
      split_request_ids_to_hash(failed_req_ids)
    end

    # Returns nil if all added, or a hash with a list of :members and/or :owners that already
    # existed in the group (e.g. {owners: ['a', 'b'], members: ['c']} or {owners: ['a']}
    def add_users_to_group_ignore_duplicates(group_id, members: [], owners: [])
      add_users_to_group(group_id, members: members, owners: owners)

      nil
    rescue MicrosoftSync::Errors::HTTPBadRequest => e
      raise unless e.response.body =~ /One or more added object references already exist/i

      add_users_to_group_via_batch(group_id, members, owners)
    end

    # Maps requests ids, e.g. ["members_a", "members_b", "owners_a"]
    # to a hash like {members: %w[a b], owners: %w[a]}
    def split_request_ids_to_hash(req_ids)
      return nil if req_ids.blank?

      req_ids
        .group_by{|id| id.split("_").first.to_sym}
        .transform_values{|ids| ids.map{|id| id.split("_").last}}
    end

    # === Teams ===
    def get_team(team_id, options={})
      request(:get, "teams/#{team_id}", query: expand_options(**options))
    end

    def team_exists?(team_id)
      get_team(team_id)
      true
    rescue MicrosoftSync::Errors::HTTPNotFound
      false
    end

    def create_education_class_team(group_id)
      body = {
        "template@odata.bind" =>
          "https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')",
        "group@odata.bind" =>
          "https://graph.microsoft.com/v1.0/groups(#{quote_value(group_id)})"
      }
      request(:post, 'teams', body: body)
    rescue MicrosoftSync::Errors::HTTPBadRequest => e
      raise unless e.response.body =~ /must have one or more owners in order to create a Team/i

      raise MicrosoftSync::Errors::GroupHasNoOwners
    rescue MicrosoftSync::Errors::HTTPConflict => e
      raise unless e.response.body =~ /group is already provisioned/i

      raise MicrosoftSync::Errors::TeamAlreadyExists
    end

    # === Users ===

    def list_users(options={}, &blk)
      get_paginated_list('users', options, &blk)
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
