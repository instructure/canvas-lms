# Copyright (C) 2018 - present Instructure, Inc.
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
# DELETE /api/v1/courses/:course_id/discussion_topics/:topic_id

require 'httparty'
require 'json'
require_relative '../../../pact_config'
require_relative '../api_client_base'

module Helper
  module ApiClient
    class Discussions < ApiClientBase
      include HTTParty
      base_uri base_uri PactConfig.mock_provider_service_base_uri
      headers 'Authorization' => 'Bearer some_token'

      def list_discussions(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/discussion_topics").body)
      rescue
        nil
      end

      def delete_discussion(course_id, topic_id)
        JSON.parse(self.class.delete("/api/v1/courses/#{course_id}/discussion_topics/#{topic_id}", query: "event=delete").body)
      rescue
        nil
      end

      def post_discussion(course_id, discussion_name)
        JSON.parse(
          self.class.post(
            "/api/v1/courses/#{course_id}/discussion_topics",
            :body =>
              {
                :discussion_topic =>
                  {
                    :title => discussion_name
                  }
              }.to_json,
            :headers => {'Content-Type' => 'application/json'}
          ).body
        )
      rescue
        nil
      end

      def post_discussion_response(course_id, topic_id, discussion_response)
        JSON.parse(
          self.class.post(
            "/api/v1/courses/#{course_id}/discussion_topics/#{topic_id}/entries",
            :body =>
              {
                :message => discussion_response
              }.to_json,
            :headers => {'Content-Type' => 'application/json'}
          ).body
        )
      rescue
        nil
      end

      def update_discussion(course_id, topic_id, update)
        JSON.parse(
          self.class.put(
            "/api/v1/courses/#{course_id}/discussion_topics/#{topic_id}",
            :body =>
              {
                :title => update
              }.to_json,
            :headers => {'Content-Type' => 'application/json'}
          ).body
        )
      rescue
        nil
      end
    end
  end
end
