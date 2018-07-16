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

describe 'Announcements', :pact => true do
  subject(:announcementsApi) {Helper::ApiClient::Announcements.new}

  it 'List Announcements' do
    canvas_lms_api.given('a student in a course with an announcement').
      upon_receiving('List Announcements').
      with(method: :get,
        headers: {
          'Authorization': 'Bearer some_token',
          'Auth-User': 'Student1',
          'Connection': 'close',
          'Host': PactConfig.mock_provider_service_base_uri,
          'Version': 'HTTP/1.1'
        },
        path: '/api/v1/announcements',
        'query' => 'context_codes[]=course_1'
      ).
      will_respond_with(
        status: 200,
        body: Pact.each_like(
          "id": 1,
          "title": "Announcement1",
          "last_reply_at": "2018-05-24T21:36:33Z",
          "delayed_post_at": nil, "posted_at": "2018-05-24T21:36:33Z",
          "assignment_id": nil,
          "root_topic_id": nil, "position": 1,
          "podcast_has_student_posts": false,
          "discussion_type": "side_comment",
          "lock_at": nil, "allow_rating": false,
          "only_graders_can_rate": false,
          "sort_by_rating": false,
          "is_section_specific": false,
          "user_name": nil,
          "discussion_subentry_count": 0,
          "permissions": {"attach": false, "update": false, "reply": true, "delete": false},
          "require_initial_post": nil, "user_can_see_posts": true,
          "podcast_url": nil, "read_state": "unread",
          "unread_count": 0, "subscribed": false, "topic_children": [],
          "group_topic_children": [], "attachments": [], "published": true,
          "can_unpublish": false, "locked": false, "can_lock": true,
          "comments_disabled": false, "author": {},
          "html_url": "http://localhost:1234/courses/1/discussion_topics/1", "url": "http://localhost:1234/courses/1/discussion_topics/1",
          "pinned": false,
          "group_category_id": nil, "can_group": false,
          "context_code": "course_1", "locked_for_user": false,
          "message": "Announcement 1 detail", "subscription_hold": "topic_is_announcement"
        )
      )
    announcementsApi.authenticate_as_user('Student1')
    response = announcementsApi.list_announcements(1)
    expect(response[0]['id']).to eq 1
    expect(response[0]['title']).to eq 'Announcement1'
  end
end
