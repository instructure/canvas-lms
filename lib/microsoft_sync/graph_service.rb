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
    GROUP_USERS_ADD_BATCH_SIZE = 20

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
      raise ArgumentError, 'Missing users to add to group' if members.empty? && owners.empty?
      if (n_total_additions = members.length + owners.length) > GROUP_USERS_ADD_BATCH_SIZE
        raise ArgumentError, "Only 20 users can be added at once. Got #{n_total_additions}."
      end

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

    def remove_group_member(group_id, user_aad_id)
      request(:delete, "groups/#{group_id}/members/#{user_aad_id}/$ref")
    end

    def remove_group_owner(group_id, user_aad_id)
      request(:delete, "groups/#{group_id}/owners/#{user_aad_id}/$ref")
    end

    # === Users ===

    def list_users(options={}, &blk)
      get_paginated_list('users', options, &blk)
    end

    # ===== Helpers =====

    def request(method, path, options={})
      options[:headers] ||= {}
      options[:headers]['Authorization'] = 'Bearer ' + LoginService.token(tenant)
      if options[:body]
        options[:headers]['Content-type'] = 'application/json'
        options[:body] = options[:body].to_json
      end

      url = path.start_with?('https:') ? path : BASE_URL + path
      Rails.logger.debug("MicrosoftSync::GraphClient: #{method} #{url}")

      response = Canvas.timeout_protection("microsoft_sync_graph") do
        HTTParty.send(method, url, options)
      end

      unless (200..299).cover?(response.code)
        raise MicrosoftSync::Errors::InvalidStatusCode.new(
          service: 'graph', tenant: tenant, response: response
        )
      end

      response.parsed_response
    end

    private

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
          quoted_values = filter_value.map{|v| filter_quote_value(v)}
          "#{filter_key} in (#{quoted_values.join(', ')})"
        else
          "#{filter_key} eq #{filter_quote_value(filter_value)}"
        end
      end.join(' and ')
    end

    def filter_quote_value(str)
      "'#{str.gsub("'", "''")}'"
    end
  end
end
