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

  context 'List Courses' do
    it 'should return JSON body' do
      canvas_lms_api.given('a student in a course').
        upon_receiving('List Your Courses').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}', { token: 'some_token' }
            ),
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

      response = courses_api.list_your_courses()
      expect(response[0]['id']).to eq 9
      expect(response[0]['name']).to eq 'Course1A'
    end
  end

  context 'List Students' do
    it 'should return JSON body' do
      canvas_lms_api.given('a student in a course').
        upon_receiving('List Students').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/users',
            { course_id: '2' }
          ),
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

      response = courses_api.list_students(2)
      expect(response[0]['id']).to eq 3
      expect(response[0]['name']).to eq 'student1'
    end
  end

    context 'List Teachers' do
    it 'should return JSON body' do
      canvas_lms_api.given('a teacher in a course').
        upon_receiving('List Teachers').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/users',
            { course_id: '2' }
          ),
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

      response = courses_api.list_teachers(2)
      expect(response[0]['id']).to eq 2
      expect(response[0]['name']).to eq 'teacher1'
    end
  end

  context 'List TAs' do
    it 'should return JSON body' do
      canvas_lms_api.given('a ta in a course').
        upon_receiving('List TAs').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/users',
            { course_id: '2' }
          ),
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

      response = courses_api.list_tas(2)
      expect(response[0]['id']).to eq 2
      expect(response[0]['name']).to eq 'ta1'
    end
  end

  context 'List Observers' do
    it 'should return JSON body' do
      canvas_lms_api.given('an observer in a course').
        upon_receiving('List Observers').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/users',
            { course_id: '2' }
          ),
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

      response = courses_api.list(2, 'observer')
      expect(response[0]['id']).to eq 2
      expect(response[0]['name']).to eq 'observer1'
    end
  end

  context 'List Discussions' do
    it 'should return JSON body' do
      canvas_lms_api.given('a student in a course with a discussion').
        upon_receiving('List Discussions').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/discussion_topics',
            { course_id: '1' }
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            "id": 1,
            "title": "No Title",
            "last_reply_at": "2018-05-29T22:36:43Z",
            "delayed_post_at": nil,
            "posted_at": "2018-05-29T22:36:43Z",
            "assignment_id": nil,
            "root_topic_id": nil,
            "position": nil,
            "podcast_has_student_posts": false,
            "discussion_type": "side_comment",
            "lock_at": nil,
            "allow_rating": false,
            "only_graders_can_rate": false,
            "sort_by_rating": false,
            "is_section_specific": false,
            "user_name": "test@test.com",
            "discussion_subentry_count": 0,
            "permissions": {
              "attach": true,
              "update": true,
              "reply": true,
              "delete": true
            },
            "require_initial_post": nil,
            "user_can_see_posts": true,
            "podcast_url": nil,
            "read_state": "read",
            "unread_count": 0,
            "subscribed": true,
            "topic_children": [],
            "group_topic_children": [],
            "attachments": [],
            "published": false,
            "can_unpublish": true,
            "locked": false,
            "can_lock": true,
            "comments_disabled": false,
            "author": {
              "id": 2,
              "display_name": "test@test.com",
              "avatar_image_url": "http://canvas.instructure.com/images/messages/avatar-50.png",
              "html_url": "http://localhost:3000/courses/1/users/2"
            },
            "html_url": "http://localhost:3000/courses/1/discussion_topics/4",
            "url": "http://localhost:3000/courses/1/discussion_topics/4",
            "pinned": false,
            "group_category_id": nil,
            "can_group": true,
            "locked_for_user": false,
            "message": nil,
            #"todo_date": nil
          )
        )

      response = courses_api.list_discussions(1)
      expect(response[0]['id']).to eq 1
      expect(response[0]['title']).to eq 'No Title'
    end
  end


  context 'List Quizzes' do
    it 'should return JSON body' do
      canvas_lms_api.given('a student in a course with a quiz').
        upon_receiving('List Quizzes').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/quizzes',
            { course_id: '1' }
          ),
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

      response = courses_api.list_quizzes(1)
      expect(response[0]['id']).to eq 1
      expect(response[0]['title']).to eq 'Test Quiz'
    end
  end


  context 'Delete a Course' do
    it 'should return JSON body' do
      canvas_lms_api.given('a teacher in a course').
        upon_receiving('Delete a Course').
        with(
          method: :delete,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}',
            { course_id: '1' }
          ),
          query: 'event=delete'
        ).
        will_respond_with(
          status: 200,
          body: Pact.like(
            'delete':true
          )
        )
      response = courses_api.delete_course(1)
      expect(response['delete']).to eq true
    end
  end

  context 'List Wiki Pages' do
    it 'should return JSON body' do
      canvas_lms_api.given('a wiki page in a course').
        upon_receiving('List Wiki Pages').
        with(
          method: :get,
          headers: {
            'Authorization' => Pact.provider_param(
              'Bearer :{token}',
              { token: 'some_token' }
            ),
            'Connection': 'close',
            'Host': PactConfig.mock_provider_service_base_uri,
            'Version': 'HTTP/1.1'
          },
          'path' => Pact.provider_param(
            '/api/v1/courses/:{course_id}/pages/',
            { course_id: '1' }
          ),
          query: ''
        ).
        will_respond_with(
          status: 200,
          body: Pact.each_like(
            "title": "WIKI Page",
            "created_at": "2018-05-30T22:50:18Z",
            "url": "wiki-page",
            "editing_roles": "teachers",
            "page_id": 1,
            "published": true,
            "hide_from_students": false,
            "front_page": false,
            "html_url": "http://localhost:3000/courses/3/pages/wiki-page",
            "updated_at": "2018-05-30T22:50:18Z",
            "locked_for_user": false
          )
        )
      response = courses_api.list_wiki_pages(1)
      expect(response[0]['title']).to eq "WIKI Page"
    end
  end
end
