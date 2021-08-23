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

    context "group discussions in a group context" do
      it "loads without errors" do
        @group_discussion_topic = group_discussion_assignment
        get "/courses/#{@course.id}/discussion_topics/#{@group_discussion_topic.id}"
        f("button[data-testid='groups-menu-btn']").click
        fj("a:contains('group 1')").click
        wait_for_ajaximations
        expect(fj("h1:contains('topic - group 1')")).to be_present
        expect_no_flash_message :error
      end
    end

    it "has a module progression section when applicable" do
      module1 = @course.context_modules.create!(:name => "module1")
      item1 = @course.assignments.create!(
        :name => "First Item",
        :submission_types => ["online_text_entry"],
        :points_possible => 20
      )
      module1.add_item(:id => item1.id, :type => 'assignment')
      item2 = @course.discussion_topics.create!(
        title: 'Second Item',
        discussion_type: 'threaded',
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
      module1.add_item(:id => item2.id, :type => 'discussion_topic')
      get "/courses/#{@course.id}/discussion_topics/#{item2.id}"
      expect(f("a[aria-label='Previous Module Item']")).to be_present
    end

    context "isolated view" do
      before :once do
        Account.site_admin.enable_feature!(:isolated_view)
      end

      it "loads older replies" do
        parent_reply = @topic.discussion_entries.create!(
          user: @teacher, message: 'I am the parent entry'
        )
        (1..6).each do |number|
          @topic.discussion_entries.create!(
            user: @teacher,
            message: "child reply number #{number}",
            parent_entry: parent_reply
          )
        end

        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        fj("button:contains('6 replies')").click
        wait_for_ajaximations
        fj("button:contains('Show older replies')").click
        wait_for_ajaximations
        expect(fj("span:contains('child reply number 1')")).to be_present
      end
    end
  end
end
