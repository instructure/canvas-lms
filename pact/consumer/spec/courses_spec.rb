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

require_relative '../courses_api_client'
require_relative 'pact_helper'

describe 'Courses', :pact => true do

  subject(:coursesApi) {CoursesApiClient.new}

  before do
    CoursesApiClient.base_uri 'localhost:1234'
  end

  context 'List Courses' do
    it 'should return JSON body' do
      canvas_api.given('a student in a course').
        upon_receiving('List Your Courses').
        with(method: :get,
          headers: {
            "Authorization" => Pact.term(
              generate: "Bearer token",
              matcher: /Bearer ([A-Za-z0-9]+)/
            ),
            "Connection": "close",
            "Host": "localhost:1234",
            "Version": "HTTP/1.1"
          },
          path: '/api/v1/courses',
          query: '').
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            "id":9,"name":"Course1A","account_id":3,
            "uuid":"9TzDqnM8dX56QI1YvlA2wKUHB4HtEZkV4i7VIJt0",
            "start_at":"2018-02-20T20:53:48Z",
            "is_public":false,"course_code":"Course1A","default_view":"assignments",
            "root_account_id":1,"enrollment_term_id":1,
            "public_syllabus":false,"public_syllabus_to_auth":false,
            "storage_quota_mb":500,"is_public_to_auth_users":false,
            "apply_assignment_group_weights":false,
            "calendar":{"ics":"http://canvas.dev/feeds/calendars/course_9TzDqnM8dX56QI1YvlA2wKUHB4HtEZkV4i7VIJt0.ics"},
            "time_zone":"America/Denver","sis_course_id":nil,"sis_import_id":nil,
            "integration_id":nil,
            "enrollments":[{"type":"teacher", "role":"TeacherEnrollment",
                            "role_id":4,"user_id":1,"enrollment_state":"active"}],
            "hide_final_grades":false,"workflow_state":"available",
            "restrict_enrollments_to_course_dates":false
          )
        )

      response = coursesApi.list_your_courses()
      expect(response[0]['id']).to eq 9
      expect(response[0]['name']).to eq 'Course1A'
    end
  end

  context 'List Students' do
    it 'should return JSON body' do
      canvas_api.given('a student in a course').
        upon_receiving('List Students').
        with(
          method: :get, headers: {
            "Authorization"  => Pact.term(
              generate: "Bearer token",
              matcher: /Bearer ([A-Za-z0-9]+)/
            ),
            "Connection": "close",
            "Host": "localhost:1234",
            "Version": "HTTP/1.1"
          },
          'path' => Pact.term(
            generate: '/api/v1/courses/1/students',
            matcher: /\/api\/v1\/courses\/[0-9]+\/students/
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            "id":3, "name":"student1", "sortable_name":"student1",
            "short_name":"student1", "sis_user_id":nil,
            "integration_id":nil, "sis_import_id":nil,
            "login_id":"student1@example.com"
          )
        )

      response = coursesApi.list_students(1)
      expect(response[0]['id']).to eq 3
      expect(response[0]['name']).to eq 'student1'
    end
  end
end
