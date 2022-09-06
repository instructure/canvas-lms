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

describe "Discussion Topic Show" do
  include_context "in-process server selenium tests"

  context "when Discussions Redesign feature flag is ON" do
    before :once do
      Account.default.enable_feature!(:react_discussions_post)
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
    end

    before do
      user_session(@teacher)
    end

    it "removes canvas headers when embedded within mobile apps" do
      resize_screen_to_mobile_width
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}?embed=true"
      expect(f("body")).not_to contain_jqcss("header#mobile-header")
      expect(f("body")).not_to contain_jqcss("header#header")
      expect(f("input[placeholder='Search entries or author...']")).to be_present
    end

    it "shows the correct number of rubrics in the find rubric option" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment: assignment
      )

      rubric = rubric_model({ context: @course })
      rubric.associate_with(assignment, @course, purpose: "grading")

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Show Rubric')").click
      fj(".find_rubric_link").click

      expect(fj(".select_rubric_link:contains(#{rubric.title})")).to be_present
      expect(ffj(".rubrics_dialog_rubric:visible").count).to eq 1
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

    it "Displays when all features are turned on" do
      Account.site_admin.enable_feature! :react_discussions_post

      gc = @course.account.group_categories.create(name: "Group Category")
      group = group_model(name: "Group", group_category: gc, context: @course.account)
      group_membership_model(group: group, user: @teacher)
      topic = discussion_topic_model(context: group)

      get "/groups/#{group.id}/discussion_topics/#{topic.id}"
      expect(fj("h1:contains('value for title')")).to be_present
    end

    it "has a module progression section when applicable" do
      module1 = @course.context_modules.create!(name: "module1")
      item1 = @course.assignments.create!(
        name: "First Item",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      module1.add_item(id: item1.id, type: "assignment")
      item2 = @course.discussion_topics.create!(
        title: "Second Item",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher
      )
      module1.add_item(id: item2.id, type: "discussion_topic")
      get "/courses/#{@course.id}/discussion_topics/#{item2.id}"
      expect(f("a[aria-label='Previous Module Item']")).to be_present
    end

    context "isolated view" do
      before :once do
        Account.site_admin.enable_feature!(:isolated_view)
      end

      it "loads older replies" do
        parent_reply = @topic.discussion_entries.create!(
          user: @teacher, message: "I am the parent entry"
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

      it "can mention users in the reply" do
        student_in_course(course: @course, name: "Jeff", active_all: true).user
        student_in_course(course: @course, name: "Jefferson", active_all: true).user
        student_in_course(course: @course, name: "Jeffrey", active_all: true).user
        get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
        f("button[data-testid='discussion-topic-reply']").click
        wait_for_ajaximations
        %w[Jeff Jefferson Jeffrey].each do |name|
          type_in_tiny "textarea", "@"
          wait_for_ajaximations
          fj("li:contains('#{name}')").click
        end
        wait_for_ajaximations
        driver.action.send_keys("HI!").perform
        wait_for_ajaximations
        fj("button:contains('Reply')").click
        wait_for_ajaximations
        expect(fj("p:contains('@Jeff@Jefferson@JeffreyHI!')")).to be_present
        expect(ff(".user_content p").count).to eq 1
      end
    end

    it "open Find Outcome dialog when adding a rubric" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment: assignment
      )

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Add Rubric')").click
      fj("a.add_rubric_link:contains('Add Rubric')").click
      f("a#add_learning_outcome_link").click

      expect(fj("span.ui-dialog-title:contains('Find Outcomes')")).to be_present
    end

    it "Able to reply to a group discussion" do
      gc = @course.account.group_categories.create(name: "Group Category")
      group = group_model(name: "Group", group_category: gc, context: @course.account)
      group_membership_model(group: group, user: @teacher)
      topic = discussion_topic_model(context: group, type: "Announcement")

      get "/groups/#{group.id}/discussion_topics/#{topic.id}"

      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      type_in_tiny "textarea", "Test Reply"
      fj("button:contains('Reply')").click
      wait_for_ajaximations
      expect(fj("p:contains('Test Reply')")).to be_present
    end
  end
end
