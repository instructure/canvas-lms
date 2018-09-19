#
# Copyright (C) 2016 - present Instructure, Inc.
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
    class Importer < Lti::ContentMigrationService::Migrator
      attr_reader :original_tool_id

      def initialize(original_tool_id)
        @original_tool_id = original_tool_id
      end

      def send_imported_content(course, _content_migration, content)
        @course = course
        @root_account = course.root_account
        load_tool!
        post_body = start_import_post_body(content)
        response = Canvas.retriable(on: Timeout::Error) do
          CanvasHttp.post(import_start_url, base_request_headers, form_data: post_body)
        end
        case response.code.to_i
        when (200..201)
          parsed_response = JSON.parse(response.body)
          unless parsed_response.empty?
            @status_url = parsed_response['status_url']
          end
        else
          raise "Unable to start import for external tool #{@tool.name} (#{response.code})"
        end
        self
      rescue Timeout::Error
        raise "Unable to start import for external tool #{@tool.name}, request timed out."
      end

      def import_completed?
        response = Canvas.retriable(on: Timeout::Error) do
          CanvasHttp.get(@status_url, base_request_headers)
        end
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
      rescue Timeout::Error
        false
      end

      private

      def start_import_post_body(content)
        Rack::Utils.build_nested_query({
          context_id: Lti::Asset.opaque_identifier_for(@course),
          data: content,
          tool_consumer_instance_guid: @root_account.lti_guid,
        }.merge(expanded_variables))
      end

      def load_tool!
        return @tool if @tool
        original_tool = ContextExternalTool.find(@original_tool_id)
        @tool = ContextExternalTool.find_external_tool(original_tool.domain, @course, @original_tool_id).tap do |t|
          unless t && t.content_migration_configured?
            raise "Unable to find external tool to import content."
          end
        end
      end

      def import_start_url
        @import_url ||= @tool.settings['content_migration']['import_start_url']
      end
    end
  end
end
