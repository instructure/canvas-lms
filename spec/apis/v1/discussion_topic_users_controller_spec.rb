# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe DiscussionTopicUsersController, type: :request do
  describe "search for users," do
    before :once do
      course_with_student active_all: true
      @topic = @course.discussion_topics.create!(title: "discussion")
    end

    it "all messageble users" do
      response = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/messageable_users",
        {
          format: "json",
          controller: "discussion_topic_users",
          action: "search",
          course_id: @course.id,
          topic_id: @topic.id,
          search: ""
        }
      )
      expect(response.first["name"]).to eq "User"
      expect(response.length).to be > 1
    end

    it "limit one per page" do
      response = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/messageable_users",
        {
          format: "json",
          controller: "discussion_topic_users",
          action: "search",
          course_id: @course.id,
          topic_id: @topic.id,
          search: "",
          per_page: 1
        }
      )
      expect(response.first["name"]).to eq "User"
      expect(response.length).to eq 1
    end

    it "with search string john" do
      user = User.last
      user.name = "John"
      user.save

      response = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/messageable_users",
        {
          format: "json",
          controller: "discussion_topic_users",
          action: "search",
          course_id: @course.id,
          topic_id: @topic.id,
          search: "john"
        }
      )
      expect(response.first["name"]).to eq "John"
      expect(response.length).to eq 1
    end

    it "with search string donald" do
      user = User.last
      user.name = "John"
      user.save

      response = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/messageable_users",
        {
          format: "json",
          controller: "discussion_topic_users",
          action: "search",
          course_id: @course.id,
          topic_id: @topic.id,
          search: "donald"
        }
      )
      expect(response.length).to eq 0
    end
  end
end
