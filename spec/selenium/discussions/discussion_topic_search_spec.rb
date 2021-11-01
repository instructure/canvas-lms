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

describe "Discussion Topic Search" do
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

    it "search only replies that matches parameter" do
      @topic.discussion_entries.create!(
        user: @teacher, message: 'bar'
      )
      (1..5).each do |number|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "foo #{number}"
        )
      end
      student = student_in_course(course: @course, name: 'Jeff', active_all: true).user
      user_session(student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("input[placeholder='Search entries or author...']").send_keys("bar")
      # rubocop:disable Lint/NoSleep
      sleep(5) # Selenium cannot catch the frontend interval to run the automark as read mutation
      # rubocop:enable Lint/NoSleep
      expect(fj("span:contains('bar')")).to be_present
      expect(f("#content")).not_to contain_jqcss("span:contains('foo')")
    end
  end
end
