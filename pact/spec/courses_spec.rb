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

require_relative 'helper'
require_relative '../pact_helper'

describe 'Courses', :pact do
  subject(:courses_api) { Helper::ApiClient::Courses.new }

  it 'should List Courses' do
    canvas_lms_api.given('a student enrolled in a course').
      upon_receiving('List Courses').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Student1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        path: '/api/v1/courses',
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          'id': 9,
          'name': 'Course1A',
          'account_id': 3,
          'uuid': '9TzDqnM8dX56QI1YvlA2wKUHB4HtEZkV4i7VIJt0',
          'start_at': '2018-02-20T20:53:48Z',
          'is_public': false,
          'course_code': 'Course1A',
          'default_view': 'assignments',
          'root_account_id': 1,
          'enrollment_term_id': 1,
          'public_syllabus': false,
          'public_syllabus_to_auth': false,
          'storage_quota_mb': 500,
          'is_public_to_auth_users': false,
          'apply_assignment_group_weights': false,
          'calendar': {
            'ics': 'http://canvas.dev/feeds/calendars/course_9TzDqnM8dX56QI1YvlA2wKUHB4HtEZkV4i7VIJt0.ics'
          },
          'time_zone': 'America/Denver',
          'enrollments': [
            { 'type': 'teacher', 'role': 'TeacherEnrollment', 'role_id': 4, 'user_id': 1, 'enrollment_state': 'active' }
          ],
          'hide_final_grades': false,
          'workflow_state': 'available',
          'restrict_enrollments_to_course_dates': false
        )
      )
    courses_api.authenticate_as_user('Student1')
    response = courses_api.list_your_courses()
    expect(response[0]['id']).to eq 9
    expect(response[0]['name']).to eq 'Course1A'
  end

  it 'should List Students' do
    canvas_lms_api.given('a student enrolled in a course').
      upon_receiving('List Students').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/users',
        query: 'enrollment_type[]=student'
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          'id': 3,
          'name': 'student1',
          'sortable_name': 'student1',
          'short_name': 'student1'
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.list_students(1)
    expect(response[0]['id']).to eq 3
    expect(response[0]['name']).to eq 'student1'
  end

  it 'should List Teachers' do
    canvas_lms_api.given('a teacher enrolled in a course').
      upon_receiving('List Teachers').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/users',
        query: 'enrollment_type[]=teacher'
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          'id': 2,
          'name': 'teacher1',
          'sortable_name': 'teacher1',
          'short_name': 'teacher1'
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.list_teachers(1)
    expect(response[0]['id']).to eq 2
    expect(response[0]['name']).to eq 'teacher1'
  end


  it 'should List TAs' do
    canvas_lms_api.given('a teacher assistant enrolled in a course').
      upon_receiving('List TAs').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'TeacherAssistant1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/users',
        query: 'enrollment_type[]=ta'
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          'id': 2,
          'name': 'ta1',
          'sortable_name': 'ta1',
          'short_name': 'ta1'
        )
      )
    courses_api.authenticate_as_user('TeacherAssistant1')
    response = courses_api.list_tas(1)
    expect(response[0]['id']).to eq 2
    expect(response[0]['name']).to eq 'ta1'
  end

  it 'should List Observers' do
    canvas_lms_api.given('an observer enrolled in a course').
      upon_receiving('List Observers').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/users',
        query: 'enrollment_type[]=observer'
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          'id': 2,
          'name': 'observer1',
          'sortable_name': 'observer1',
          'short_name': 'observer1'
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.list(1, 'observer')
    expect(response[0]['id']).to eq 2
    expect(response[0]['name']).to eq 'observer1'
  end

  it 'should List Quizzes' do
    canvas_lms_api.given('a quiz in a course').
      upon_receiving('List Quizzes').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1/quizzes',
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          "id": 1,
          "title": "Test Quiz",
          "html_url": "http://localhost:3000/courses/2/quizzes/1",
          "mobile_url": "http://localhost:3000/courses/2/quizzes/1?force_user=1&persist_headless=1",
          "description": "<p>Are we in a simulation?</p>",
          "quiz_type": "assignment",
          "time_limit": nil,
          "shuffle_answers": true,
          "show_correct_answers": true,
          "scoring_policy": "keep_highest",
          "allowed_attempts": 1,
          "one_question_at_a_time": false,
          "question_count": 0,
          "points_possible": 0.1,
          "cant_go_back": false,
          "access_code": nil,
          "ip_filter": nil,
          "due_at": nil,
          "lock_at": nil,
          "unlock_at": nil,
          "published": true,
          "unpublishable": true,
          "locked_for_user": true,
          "lock_info": {
            "missing_permission": "participate_as_student",
            "asset_string": "quizzes:quiz_1"
          },
          "lock_explanation": "This quiz is currently locked.",
          "hide_results": nil,
          "show_correct_answers_at": nil,
          "hide_correct_answers_at": nil,
          "all_dates": [
            {
              "due_at": nil,
              "unlock_at": nil,
              "lock_at": nil,
              "base": true
            }
          ],
          "can_unpublish": true,
          "can_update": true,
          "require_lockdown_browser": false,
          "require_lockdown_browser_for_results": false,
          "require_lockdown_browser_monitor": false,
          "lockdown_browser_monitor_data": nil,
          "speed_grader_url": nil,
          "permissions": {
            "read_statistics": true,
            "manage": true,
            "read": true,
            "update": true,
            "create": true,
            "submit": true,
            "preview": true,
            "delete": true,
            "grade": true,
            "review_grades": true,
            "view_answer_audits": true
          },
          "quiz_reports_url": "http://localhost:3000/api/v1/courses/2/quizzes/1/reports",
          "quiz_statistics_url": "http://localhost:3000/api/v1/courses/2/quizzes/1/statistics",
          "message_students_url": "http://localhost:3000/api/v1/courses/2/quizzes/1/submission_users/message",
          "section_count": 1,
          "quiz_submission_versions_html_url": "http://localhost:3000/courses/2/quizzes/1/submission_versions",
          "assignment_id": nil,
          "one_time_results": false,
          "only_visible_to_overrides": false,
          "assignment_group_id": nil,
          "show_correct_answers_last_attempt": false,
          "version_number": 2,
          "has_access_code": false,
          "post_to_sis": nil
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.list_quizzes(1)
    expect(response[0]['id']).to eq 1
    expect(response[0]['title']).to eq 'Test Quiz'
  end

  it 'should Delete a Course' do
    canvas_lms_api.given('a teacher enrolled in a course').
      upon_receiving('Delete a Course').
      with(
        method: :delete,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/courses/1',
        query: 'event=delete'
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          'delete':true
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.delete_course(1)
    expect(response['delete']).to eq true
  end

  it 'should Create a Course' do
    skip('failing jenkins')
    canvas_lms_api.given('a site admin').
      upon_receiving('Create a Course').
      with(
        method: :post,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'SiteAdmin1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1',
          'Content-Type': 'application/json'
        },
        'path' => '/api/v1/accounts/1/courses',
        'body' =>
        {
          'course':
          {
            'name': 'new course',
            'start_at': '2014-01-01T00:00:00Z',
            'conclude_at': '2015-01-02T00:00:00Z'
          }
        },
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          "id": 9,
          "name": "new course",
          "account_id": 1,
          "uuid": "zQmOIIBHee7zRd4EwXAEDgmoWr8n9uLM2AhD8uZ5",
          "start_at": "2014-01-01T00:00:00Z",
          "conclude_at": "2015-01-01T00:00:00Z",
          "grading_standard_id": nil,
          "is_public": nil,
          "allow_student_forum_attachments": false,
          "course_code": "Unnamed",
          "default_view": "modules",
          "root_account_id": 1,
          "enrollment_term_id": 1,
          "open_enrollment": nil,
          "allow_wiki_comments": nil,
          "self_enrollment": nil,
          "license": nil,
          "restrict_enrollments_to_course_dates": false,
          "end_at": "2015-01-01T00:00:00Z",
          "public_syllabus": false,
          "public_syllabus_to_auth": false,
          "storage_quota_mb": 500,
          "is_public_to_auth_users": false,
          "hide_final_grades": false,
          "apply_assignment_group_weights": false,
          "calendar": {
              "ics": "http://localhost:3000/feeds/calendars/course_zQmOIIBHee7zRd4EwXAEDgmoWr8n9uLM2AhD8uZ5.ics"
          },
          "time_zone": "America/Denver",
          "sis_course_id": nil,
          "sis_import_id": nil,
          "integration_id": nil,
          "workflow_state": "unpublished"
        )
      )
    courses_api.authenticate_as_user('SiteAdmin1')
    response = courses_api.create_new_course(1)
    expect(response["name"]).to eq "new course"
  end

  it 'should Update a Course' do
    canvas_lms_api.given('a teacher enrolled in a course').
      upon_receiving('Update a Course').
      with(
        method: :put,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Teacher1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1',
          'Content-Type': 'application/json'
        },
        'path' => '/api/v1/courses/1',
        'body' =>
        {
          'course':
          {
            'name': 'updated course',
          }
        },
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.like(
          "id": 9,
          "name": "updated course",
          "account_id": 1,
          "uuid": "zQmOIIBHee7zRd4EwXAEDgmoWr8n9uLM2AhD8uZ5",
          "start_at": "2014-01-01T00:00:00Z",
          "is_public": true,
          "grading_standard_id": nil,
          "course_code": "Unnamed",
          "default_view": "modules",
          "root_account_id": 1,
          "enrollment_term_id": 1,
          "restrict_enrollments_to_course_dates": false,
          "end_at": nil,
          "public_syllabus": false,
          "public_syllabus_to_auth": false,
          "storage_quota_mb": 500,
          "is_public_to_auth_users": false,
          "hide_final_grades": false,
          "apply_assignment_group_weights": false,
          "calendar": {
              "ics": "http://localhost:3000/feeds/calendars/course_zQmOIIBHee7zRd4EwXAEDgmoWr8n9uLM2AhD8uZ5.ics"
          },
          "time_zone": "America/Denver",
          "sis_course_id": nil,
          "integration_id": nil,
          "workflow_state": "unpublished"
        )
      )
    courses_api.authenticate_as_user('Teacher1')
    response = courses_api.update_course(1)
    expect(response["name"]).to eq "updated course"
  end

  context 'Teacher not in a course' do
    it 'should Give a 401 response' do
      canvas_lms_api.given('a teacher not in a course').
        upon_receiving('List Students').
        with(
          method: :get,
          headers: {
            'Authorization': 'Bearer some_token',
            'Auth-User': 'Teacher2',
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => '/api/v1/courses/1/users',
          query: 'enrollment_type[]=student'
        ).
        will_respond_with(
          status: 401,
          body: Pact.like(
            "status": "unauthorized",
            "errors": [
              {
                "message": "user not authorized to perform that action"
              },
            ]
          )
        )
      courses_api.authenticate_as_user('Teacher2')
      response = courses_api.list_students(1)
      expect(response["status"]).to eq "unauthorized"
    end
  end
end
