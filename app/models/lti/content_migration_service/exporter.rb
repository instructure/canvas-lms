# frozen_string_literal: true

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
    # Exports any external content defined by the ContextExternalTool associated
    # with the Course being exported, as detailed in
    # `docs/api/tools_xml.md#Content Migration support`. Export is done by POSTing
    # to the tool's content_migration.export_start_url, and then retrieving any
    # content from the url that is returned from that POST. The default format for
    # this POST body is a nested query string, but is sent as JSON if the tool
    # specifies as much in its content_migration.export_format.
    # This code is referenced by `lib/canvas/migration/external_content/migrator.rb`,
    # and eventually by `lib/cc/cc_exporter.rb` and `lib/canvas/migration/worker/course_copy_worker.rb`,
    # which is called as a delayed job during a course copy or export.
    class Exporter < Lti::ContentMigrationService::Migrator
      def initialize(course, tool, options)
        @course = course
        @tool = tool
        @options = options
      end

      def export_completed?
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

      def retrieve_export
        return nil if @export_status == FAILED_STATUS
        response = Canvas.retriable(on: Timeout::Error) do
          CanvasHttp.get(@fetch_url, base_request_headers)
        end
        if response.code.to_i == 200
          JSON.parse(response.body)
        else
          raise "Unable to fetch export data from #{@status_url}: #{response.code} #{response.message}. (#{response.body})"
        end
      rescue Timeout::Error
        raise "Fetching data from #{@tool.name} timed out."
      end

      def start!
        return if defined? @status_url

        response = Canvas.retriable(on: Timeout::Error) do
          case export_format
          when JSON_FORMAT
            CanvasHttp.post(export_start_url, base_request_headers, body: start_export_post_body.to_json, content_type: 'application/json')
          else
            CanvasHttp.post(export_start_url, base_request_headers, form_data: Rack::Utils.build_nested_query(start_export_post_body))
          end
        end
        case response.code.to_i
        when (200..201)
          parsed_response = JSON.parse(response.body)
          unless parsed_response.empty?
            @status_url = parsed_response['status_url']
            @fetch_url = parsed_response['fetch_url']
          end
        end
      rescue JSON::JSONError, Timeout::Error
        # We're ok with this, we'll just assume it failed.
      end

      def successfully_started?
        !!@status_url && !!@fetch_url
      end

      private

      def base_post_body
        {
          context_id: Lti::Asset.opaque_identifier_for(@course),
          tool_consumer_instance_guid: root_account.lti_guid,
        }
      end

      def export_start_url
        @tool.settings.dig(:content_migration, :export_start_url)
      end

      def export_format
        @tool.settings.dig(:content_migration, :export_format)
      end

      def start_export_post_body
        base_post_body.
          merge(expanded_variables).
          merge(selected_assets)
      end

      def selected_assets
        (@options[:selective] ? {custom_exported_assets: @options[:exported_assets]} : {})
      end
    end
  end
end
