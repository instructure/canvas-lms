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
require_relative "../common"

describe "Discussion Topic Search" do
  include_context "in-process server selenium tests"

  context "when Discussions Redesign feature flag is ON" do
    before :once do
      Account.default.enable_feature!(:react_discussions_post)
    end

    before do
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
    end

    it "search only replies that matches parameter" do
      @topic.discussion_entries.create!(
        user: @teacher, message: "bar"
      )
      (1..5).each do |number|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "foo #{number}"
        )
      end
      student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f("input[placeholder='Search entries or author...']").send_keys("bar")
      wait_for_ajaximations
      wait_for(method: nil, timeout: 5) { fj("span:contains('bar')").displayed? }
      expect(fj("span:contains('bar')")).to be_present
      expect(f("#content")).not_to contain_jqcss("span:contains('foo')")
    end

    it "cannot search by entry author when partially_anonymous" do
      @teacher.name = "Blue"
      @teacher.save!

      partial_anonymity_topic = @course.discussion_topics.create!(
        title: "Partial Anonymity Topic",
        user: @teacher,
        anonymous_state: "partial_anonymity"
      )

      partial_anonymity_topic.discussion_entries.create!(
        user: @teacher,
        message: "Green",
        is_anonymous_author: true
      )

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{partial_anonymity_topic.id}"
      search_input = f("input[placeholder='Search entries...']")
      search_input.send_keys("Blue")
      wait_for(method: nil, timeout: 5) { fj("span:contains('No Results Found')").displayed? }
      expect(fj("span:contains('No Results Found')")).to be_present
      get "/courses/#{@course.id}/discussion_topics/#{partial_anonymity_topic.id}"
      search_input = f("input[placeholder='Search entries...']")
      search_input.send_keys("Green")
      wait_for(method: nil, timeout: 5) { fj("span:contains('1 results found')").displayed? }
      expect(fj("span:contains('1 result found')")).to be_present
    end

    it "preserves search term upon changing filter" do
      @topic.discussion_entries.create!(
        user: @teacher,
        message: "foo bar"
      )

      student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(student)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      wait_for_ajaximations

      f("input[placeholder='Search entries or author...']").send_keys("foo")
      wait_for(method: nil, timeout: 5) { fj("span:contains('foo bar)").displayed? }
      expect(fj("span:contains('foo bar')")).to be_present
      f("span.discussions-filter-by-menu").click
      wait_for_ajaximations
      fj("li li:contains('Unread')").click
      wait_for_ajaximations

      expect(f("input[data-testid='search-filter']").attribute("value")).to eq "foo"
    end

    it "resets to page 1 upon clearing search term" do
      (1..2).each do |number|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "foo #{number}"
        )
      end

      @topic.discussion_entries.create!(
        user: @teacher, message: "bar"
      )

      student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(student)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      # rubocop:disable Specs/NoExecuteScript
      driver.execute_script("ENV.per_page = 1")
      # rubocop:enable Specs/NoExecuteScript

      expect(fj("h2:contains('#{@topic_title}')")).to be_present
      f("input[placeholder='Search entries or author...']").send_keys("foo")
      wait_for_ajaximations

      expect(f("body")).not_to contain_jqcss("h2:contains('#{@topic_title}')")
      expect(fj("span:contains('foo 2')")).to be_present
      expect(f("#content")).not_to contain_jqcss("span:contains('bar')")

      fj("button:contains('2')").click
      wait_for_ajaximations
      expect(fj("span:contains('foo 1')")).to be_present
      expect(fj("button[aria-current='page']:contains('2')")).to be_present

      f("button[data-testid='clear-search-button']").click
      wait_for_ajaximations

      expect(fj("h2:contains('#{@topic_title}')")).to be_present
      expect(fj("button[aria-current='page']:contains('1')")).to be_present
      expect(fj("span:contains('bar')")).to be_present
    end

    it "resets to page 1 upon changing filter" do
      # 10 is needed so that they don't get all marked as read on initial view
      (1..10).each do |number|
        @topic.discussion_entries.create!(
          user: @teacher,
          message: "foo #{number}"
        )
      end

      student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(student)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      # rubocop:disable Specs/NoExecuteScript
      driver.execute_script("ENV.per_page = 1")
      # rubocop:enable Specs/NoExecuteScript

      wait_for_ajaximations

      expect(fj("span:contains('foo 10')")).to be_present
      expect(f("#content")).not_to contain_jqcss("span:contains('foo 9')")

      fj("button:contains('2')").click
      wait_for_ajaximations
      expect(fj("span:contains('foo 9')")).to be_present
      expect(fj("button[aria-current='page']:contains('2')")).to be_present

      f("span.discussions-filter-by-menu").click
      wait_for_ajaximations
      fj("li li:contains('Unread')").click
      wait_for_ajaximations

      expect(fj("button[aria-current='page']:contains('1')")).to be_present
    end
  end
end
