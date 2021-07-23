# frozen_string_literal: true

#
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
require_relative '../common'

describe "Discussion Topic Show" do
  include_context "in-process server selenium tests"

  context "when Discussions Redesign feature flag is ON" do
    before :once do
      Account.default.enable_feature!(:react_discussions_post)
      course_with_teacher(active_course: true, active_all: true, name: 'teacher')
      @topic_title = 'Our Discussion Topic'
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        discussion_type: 'threaded',
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
    end
    
    before(:each) do
      user_session(@teacher)
    end
    
    it "displays properly for a teacher" do
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("input[placeholder='Search entries or author...']")).to be_present
      expect(fj("span:contains('Jul 9, 2017')")).to be_present
      expect(fj("span[data-testid='author_name']:contains('teacher')")).to be_present
      expect(f("span[data-testid='pill-Author']")).to be_present
      expect(f("span[data-testid='pill-Teacher']")).to be_present
      f("button[data-testid='discussion-post-menu-trigger']").click
      expect(fj("span:contains('Mark All as Read')")).to be_present
      expect(fj("span:contains('Edit')")).to be_present
      expect(fj("span:contains('Delete')")).to be_present
      expect(fj("span:contains('Close for Comments')")).to be_present
      expect(fj("span:contains('Send To...')")).to be_present
      expect(fj("span:contains('Copy To...')")).to be_present
    end
  end
end
