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

    attr_reader :tenant

    def initialize(tenant)
      @tenant = tenant
    end

    # === Education Classes: ===

    def list_education_classes(options={})
      request(:get, 'education/classes', query: expand_options(**options))['value']
    end

    def create_education_class(params)
      request(:post, 'education/classes', body: params)
    end

    # === Groups: ===

    def update_group(group_id, params)
      request(:patch, "groups/#{group_id}", body: params)
    end

    # Used for debugging. Example:
    # get_group('id', select: %w[microsoft_EducationClassLmsExt microsoft_EducationClassSisExt])
    def get_group(group_id, options={})
      request(:get, "groups/#{group_id}", query: expand_options(**options))
    end

    # ===== Helpers =====

    def request(method, path, options={})
      options[:headers] ||= {}
      options[:headers]['Authorization'] = 'Bearer ' + LoginService.token(tenant)
      if options[:body]
        options[:headers]['Content-type'] = 'application/json'
        options[:body] = options[:body].to_json
      end

      url = BASE_URL + path
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

    # Builds a query string (hash) from options used by get or list endpoints
    def expand_options(filter: {}, select: [])
      {}.tap do |query|
        query['$filter'] = filter_clause(filter) unless filter.empty?
        query['$select'] = select.join(',') unless select.empty?
      end
    end

    def filter_clause(filter)
      filter.map do |filter_key, filter_value|
        "#{filter_key} eq #{filter_quote_value(filter_value)}"
      end.join(' and ')
    end

    def filter_quote_value(str)
      "'#{str.gsub("'", "''")}'"
    end
  end
end
