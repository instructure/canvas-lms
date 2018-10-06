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

describe 'Student Planner', :pact do
  subject(:planner_api) { Helper::ApiClient::Planner.new }

  it 'should List Planner items' do
    canvas_lms_api.given('a student in a course with an assignment').
      upon_receiving('List Planner items').
      with(
        method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Student1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        'path' => '/api/v1/planner/items',
        query: ''
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          "context_type":"Course",
          "context_name":"Untitled Course",
          "context_image":"/path/to/course/image.png",
          "course_id":1,
          "plannable_id":1,
          "new_activity":false,
          "submissions":
            {"submitted":false,
             "excused":false,
             "graded":false,
             "late":false,
             "missing":false,
             "needs_grading":false,
             "has_feedback":false
            },
          "plannable_type":"assignment",
          "plannable_date":"2018-07-19T15:25:00Z",
          "plannable":
            {"id":1,
             "due_at":"2018-07-19T15:25:05Z",
             "grading_type":"points",
             "assignment_group_id":1,
             "created_at":"2018-07-18T15:25:05Z",
             "updated_at":"2018-07-18T15:25:05Z",
             "peer_reviews":false,
             "automatic_peer_reviews":false,
             "position":1,
             "grade_group_students_individually":false,
             "anonymous_peer_reviews":false,
             "post_to_sis":false,
             "moderated_grading":false,
             "omit_from_final_grade":false,
             "intra_group_peer_reviews":false,
             "anonymous_instructor_annotations":false,
             "anonymous_grading":false,
             "graders_anonymous_to_graders":false,
             "grader_comments_visible_to_graders":true,
             "grader_names_visible_to_final_grader":true,
             "secure_params":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsdGlfYXNzaWdubWVudF9pZCI6ImJkMmEyZDQyLWEwMTMtNGIxNi05NDNmLTE5M2M2ZDkxYWRjNiJ9.QwuN7fxH67cv4oGeCZ46W1qQnLRTHs_DEntDXW2emKo",
             "course_id":1,
             "name":"Assignment 1",
             "submission_types":["online_text_entry"],
             "has_submitted_submissions":false,
             "due_date_required":false,"max_name_length":255,
             "in_closed_grading_period":false,
             "is_quiz_assignment":false,
             "can_duplicate":true,
             "workflow_state":"published",
             "muted":false,
             "html_url":"http://localhost:1234/courses/1/assignments/1",
             "published":true,
             "only_visible_to_overrides":false,
             "locked_for_user":false,
             "submissions_download_url":"http://localhost:1234/courses/1/assignments/1/submissions?zip=1",
             "anonymize_students":false
            },
          "html_url":"/courses/1/assignments/1")
      )
    planner_api.authenticate_as_user('Student1')
    response = planner_api.list_items
    expect(response[0]['plannable_id']).to eq 1
    expect(response[0]['plannable_type']).to eq 'assignment'
  end
end

