#
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

require 'httparty'
require 'json'
require_relative '../../../pact_config'
require_relative '../api_client_base'

module Helper
  module ApiClient
    class Courses < ApiClientBase
      include HTTParty
      base_uri PactConfig.mock_provider_service_base_uri
      headers 'Authorization' => 'Bearer some_token'

      def list_your_courses
        JSON.parse(self.class.get('/api/v1/courses').body)
      rescue
        nil
      end

      def list_quizzes(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/quizzes").body)
      rescue
        nil
      end

      def list_sections(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/sections").body)
      rescue
        nil
      end

      def delete_course(course_id)
        JSON.parse(self.class.delete("/api/v1/courses/#{course_id}", query: "event=delete").body)
      rescue
        nil
      end

      def list(course_id, enrollment_type)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/users", query: "enrollment_type[]=#{enrollment_type}").body)
      rescue
        nil
      end

      def list_teachers(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/users", query: "enrollment_type[]=teacher").body)
      rescue
        nil
      end

      def list_tas(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/users", query: "enrollment_type[]=ta").body)
      rescue
        nil
      end

      def list_students(course_id)
        JSON.parse(self.class.get("/api/v1/courses/#{course_id}/users", query: "enrollment_type[]=student").body)
      rescue
        nil
      end

      def create_new_course(account_id)
        JSON.parse(
          self.class.post("/api/v1/accounts/#{account_id}/courses",
          :body =>
          {
            :course =>
            {
              :name => 'new course',
              :start_at => '2014-01-01T00:00:00Z',
              :conclude_at => '2015-01-02T00:00:00Z'
            }
          }.to_json,
          :headers => {'Content-Type' => 'application/json'}).body
        )
      rescue
        nil
      end

      def update_course(course_id)
        JSON.parse(
          self.class.put("/api/v1/courses/#{course_id}",
          :body =>
          {
            :course =>
            {
              :name => 'updated course'
            }
          }.to_json,
          :headers => {'Content-Type' => 'application/json'}).body
        )
      rescue
        nil
      end
    end
  end
end
