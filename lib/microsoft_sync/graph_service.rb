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
# provide, which has no knowledge of Canvas models, so should be mainly used
# via CanvasGraphService, which does.
#
module MicrosoftSync
  class GraphService
    BASE_URL = 'https://graph.microsoft.com/v1.0/'
    DIRECTORY_OBJECT_PREFIX = 'https://graph.microsoft.com/v1.0/directoryObjects/'
    GROUP_USERS_BATCH_SIZE = 20
    STATSD_PREFIX = 'microsoft_sync.graph_service'

    class ApplicationNotAuthorizedForTenant < StandardError
      include Errors::GracefulCancelErrorMixin
    end

    class BatchRequestFailed < StandardError; end

    attr_reader :tenant

    def initialize(tenant)
      @tenant = tenant
    end

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
      failed_req_ids = run_batch(reqs) do |resp|
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
      failed_req_ids = run_batch(reqs) do |r|
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
      raise unless e.response_body =~ /One or more added object references already exist/i

      add_users_to_group_via_batch(group_id, members, owners)
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
      raise unless e.response_body =~ /must have one or more owners in order to create a Team/i

      raise MicrosoftSync::Errors::GroupHasNoOwners
    rescue MicrosoftSync::Errors::HTTPConflict => e
      raise unless e.response_body =~ /group is already provisioned/i

      raise MicrosoftSync::Errors::TeamAlreadyExists
    end

    # === Users ===

    def list_users(options={}, &blk)
      get_paginated_list('users', options, &blk)
    end

    # ===== Helpers =====

    def request(method, path, options={})
      statsd_tags = {
        msft_endpoint:
          InstStatsd::Statsd.escape("#{method.to_s.downcase}_#{path.split('/').first}")
      }

      options[:headers] ||= {}
      options[:headers]['Authorization'] = 'Bearer ' + LoginService.token(tenant)
      if options[:body]
        options[:headers]['Content-type'] = 'application/json'
        options[:body] = options[:body].to_json
      end

      url = path.start_with?('https:') ? path : BASE_URL + path
      Rails.logger.info("MicrosoftSync::GraphClient: #{method} #{url}")

      response = Canvas.timeout_protection("microsoft_sync_graph", raise_on_timeout: true) do
        InstStatsd::Statsd.time("#{STATSD_PREFIX}.time", tags: statsd_tags) do
          HTTParty.send(method, url, options)
        end
      end

      if application_not_authorized_response?(response)
        raise ApplicationNotAuthorizedForTenant
      elsif !(200..299).cover?(response.code)
        raise MicrosoftSync::Errors::HTTPInvalidStatus.for(
          service: 'graph', tenant: tenant, response: response
        )
      end

      result = response.parsed_response
      InstStatsd::Statsd.increment(statsd_name, tags: statsd_tags)
      result
    rescue => error
      statsd_tags[:status_code] = response&.code&.to_s || 'unknown'
      InstStatsd::Statsd.increment(statsd_name(error), tags: statsd_tags)
      raise
    end

    private

    def application_not_authorized_response?(response)
      (
        response.code == 401 &&
        response.body.include?('The identity of the calling application could not be established.')
      ) || (
        response.code == 403 &&
        response.body.include?('Required roles claim values are not provided')
      )
    end

    def statsd_name(error=nil)
      name = case error
             when nil then 'success'
             when MicrosoftSync::Errors::HTTPNotFound then 'notfound'
             when MicrosoftSync::Errors::HTTPTooManyRequests then 'throttled'
             else 'error'
             end
      "#{STATSD_PREFIX}.#{name}"
    end

    PAGINATED_NEXT_LINK_KEY = '@odata.nextLink'
    PAGINATED_VALUE_KEY = 'value'

    def get_paginated_list(endpoint, options)
      response = request(:get, endpoint, query: expand_options(**options))
      return response[PAGINATED_VALUE_KEY] unless block_given?

      loop do
        value = response[PAGINATED_VALUE_KEY]
        next_link = response[PAGINATED_NEXT_LINK_KEY]
        yield value, next_link

        break if next_link.nil?

        response = request(:get, next_link)
      end
    end

    # Builds a query string (hash) from options used by get or list endpoints
    def expand_options(filter: {}, select: [])
      {}.tap do |query|
        query['$filter'] = filter_clause(filter) unless filter.empty?
        query['$select'] = select.join(',') unless select.empty?
      end
    end

    def filter_clause(filter)
      filter.map do |filter_key, filter_value|
        if filter_value.is_a?(Array)
          quoted_values = filter_value.map{|v| quote_value(v)}
          "#{filter_key} in (#{quoted_values.join(', ')})"
        else
          "#{filter_key} eq #{quote_value(filter_value)}"
        end
      end.join(' and ')
    end

    def quote_value(str)
      "'#{str.gsub("'", "''")}'"
    end

    # ==== Helpers for removing and adding in batch ===

    def check_group_users_args(members, owners)
      raise ArgumentError, 'Missing members/owners' if members.empty? && owners.empty?

      if (n_total_additions = members.length + owners.length) > GROUP_USERS_BATCH_SIZE
        raise ArgumentError, "Only #{GROUP_USERS_BATCH_SIZE} users can be batched at " \
          "once. Got #{n_total_additions}."
      end
    end

    # Uses Microsoft API's JSON batching to run requests in parallel with one
    # HTTP request. Expected failures can be ignored by passing in a block which checks
    # the response. Other non-2xx responses cause a BatchRequestFailed error.
    # Returns a list of ids of the requests that were ignored.
    def run_batch(requests, &response_should_be_ignored)
      ignored_request_ids = []
      failed = []

      response = request(:post, '$batch', body: { requests: requests })
      response['responses'].each do |subresponse|
        if response_should_be_ignored[subresponse]
          ignored_request_ids << subresponse['id']
        elsif subresponse['status'] < 200 || subresponse['status'] >= 300
          failed << subresponse
        end
      end

      if failed.any?
        codes = failed.map{|resp| resp['status']}
        bodies = failed.map{|resp| resp['body'].to_s.truncate(500)}
        msg = "Batch of #{failed.count}: codes #{codes}, bodies #{bodies.inspect}"
        raise BatchRequestFailed, msg
      end

      ignored_request_ids
    end

    # Maps requests ids, e.g. ["members_a", "members_b", "owners_a"]
    # to a hash like {members: %w[a b], owners: %w[a]}
    def split_request_ids_to_hash(req_ids)
      return nil if req_ids.blank?

      req_ids
        .group_by{|id| id.split("_").first.to_sym}
        .transform_values{|ids| ids.map{|id| id.split("_").last}}
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
