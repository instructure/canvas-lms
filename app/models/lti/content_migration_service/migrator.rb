# Copyright (C) 2016 Instructure, Inc.
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

module Lti
  module ContentMigrationService
    class Migrator
      FAILED_STATUS = 'failed'.freeze
      SUCCESSFUL_STATUS = 'completed'.freeze
      JWT_LIFETIME = 30.seconds

      def initialize(course, tool)
        @course = course
        @tool = tool
      end

      def export_completed?
        response = CanvasHttp.get(@status_url, base_request_headers)
        if response.code.to_i == 200
          parsed_response = JSON.parse(response.body)
          @export_status = parsed_response['status']
          case @export_status
          when SUCCESSFUL_STATUS
            true
          when FAILED_STATUS
            raise parsed_response['message']
          else
            false
          end
        end
      end

      def retrieve_export
        return nil if @export_status == FAILED_STATUS
        response = CanvasHttp.get(@fetch_url, base_request_headers)
        if response.code.to_i == 200
          JSON.parse(response.body)
        else
          raise "Unable to fetch export data from #{@status_url}: #{response.code} #{response.message}. (#{response.body})"
        end
      end

      def start!
        return if defined? @status_url

        CanvasHttp.post(export_start_url, base_request_headers, form_data: start_export_post_body) do |response|
          case response.code.to_i
          when (200..201)
            parsed_response = JSON.parse(response.body)
            unless parsed_response.empty?
              @status_url = parsed_response['status_url']
              @fetch_url = parsed_response['fetch_url']
            end
          end
        end
      rescue JSON::JSONError
        # We're ok with this, we'll just assume it failed.
      end

      def successfully_started?
        !!@status_url && !!@fetch_url
      end

      private

      def expanded_variables
        return @expanded_variabled if @expanded_variables
        variable_expander = Lti::VariableExpander.new(root_account, @course, nil, tool: @tool)
        @expanded_variables = variable_expander.expand_variables!(
          @tool.set_custom_fields('content_migration')
        )
      end

      def export_start_url
        @tool.settings['content_migration']['export_start_url']
      end

      def generate_jwt
        key = JSON::JWK.new({k: @tool.shared_secret, kid: @tool.consumer_key, kty: 'oct'})
        Canvas::Security.create_jwt({}, JWT_LIFETIME.from_now, key)
      end

      def base_request_headers
        {'Authorization' => "Bearer #{generate_jwt}"}
      end

      def root_account
        @course.root_account
      end

      def start_export_post_body
        {
          context_id: Lti::Asset.opaque_identifier_for(@course),
          tool_consumer_instance_guid: root_account.lti_guid,
        }.merge(expanded_variables)
      end
    end
  end
end
