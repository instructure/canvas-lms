# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"

describe "Discussion Pin Post" do
  include_context "in-process server selenium tests"

  context "when logged in as teacher with feature flag enabled" do
    before :once do
      course_with_teacher(active_all: true)
      @course.enable_feature!(:discussion_pin_post)
    end

    it "can pin/unpin a discussion entry" do
      topic = @course.discussion_topics.create!(
        title: "Topic for pinning",
        message: "I want to pin something!",
        user: @teacher
      )
      topic.discussion_entries.create!(
        message: "How about you pin this message?",
        user: @teacher
      )

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).to contain_jqcss("[data-testid='threading-toolbar-pin']")

      f("button[data-testid='threading-toolbar-pin']").click
      expect(f("[data-testid='threading-toolbar-pin']").text).to include "Unpin"
      expect(f("[data-testid='pinned-by-user-text']").text).to include "Pinned by nobody@example.com"

      f("button[data-testid='threading-toolbar-pin']").click
      expect(f("[data-testid='threading-toolbar-pin']").text).to include "Pin"
      expect(f("body")).to_not contain_jqcss("[data-testid='pinned-by-user-text']")
    end
  end

  context "when feature flag is disabled" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "pin features are not present even when post is pinned" do
      topic = @course.discussion_topics.create!(
        title: "Topic for pinning",
        message: "I want to pin something!",
        user: @teacher
      )
      topic.discussion_entries.create!(
        message: "How about you pin this message?",
        user: @teacher,
        pin_type: "reply",
        pinned_by: @teacher
      )

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"

      expect(f("body")).not_to contain_jqcss("[data-testid='threading-toolbar-pin']")
      expect(f("body")).to_not contain_jqcss("[data-testid='pinned-by-user-text']")
    end
  end
end
