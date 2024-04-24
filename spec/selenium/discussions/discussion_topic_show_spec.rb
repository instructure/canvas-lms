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
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "pages/discussion_page"

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
      mod = @course.context_modules.create! name: "module 1"
      mod.add_item(type: "discussion_topic", id: @topic.id)
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
      expect(f("body")).not_to contain_jqcss("div#module_sequence_footer")
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
        assignment:
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
      expect(fj("span[data-testid='author_name']:contains('teacher')")).to be_present
      expect(ff("ul[data-testid='pill-container'] li").collect(&:text)).to eq ["AUTHOR", "TEACHER"]
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

        # NOTE: this is not 10 Unread, it's 2 sibling elements, 1 is group 1, the other is 0 Unread
        fj("a:contains('group 10 Unread')").click
        wait_for_ajaximations
        expect(fj("h1:contains('topic - group 1')")).to be_present
        expect_no_flash_message :error
      end
    end

    it "Displays when all features are turned on" do
      Account.site_admin.enable_feature! :react_discussions_post

      gc = @course.account.group_categories.create(name: "Group Category")
      group = group_model(name: "Group", group_category: gc, context: @course.account)
      group_membership_model(group:, user: @teacher)
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

    it "displays module prerequisites" do
      student_in_course(active_all: true)
      user_session(@student)
      module1 = @course.context_modules.create!(name: "module1")
      module1.unlock_at = Time.now + 1.day

      topic = @course.discussion_topics.create!(
        title: "Ya Ya Ding Dong",
        user: @teacher,
        message: "By Will Ferrell and My Marianne",
        workflow_state: "published"
      )
      module1.add_item(type: "discussion_topic", id: topic.id)
      module1.save!

      get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
      wait_for_ajaximations

      expect(fj("span:contains('This topic is part of the module #{module1.name}, which is locked')")).to be_present
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
        assignment:
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
      group_membership_model(group:, user: @teacher)
      topic = discussion_topic_model(context: group, type: "Announcement")

      get "/groups/#{group.id}/discussion_topics/#{topic.id}"

      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      type_in_tiny "textarea", "Test Reply"
      fj("button:contains('Reply')").click
      wait_for_ajaximations
      expect(fj("p:contains('Test Reply')")).to be_present
    end

    context "Assign To option" do
      include ItemsAssignToTray
      include ContextModulesCommon

      before :once do
        differentiated_modules_on
        @discussion = @course.discussion_topics.create!(
          title: "Discussion 1",
          discussion_type: "threaded",
          posted_at: "2017-07-09 16:32:34",
          user: @teacher
        )
      end

      it "renders Assign To option" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"

        Discussion.click_assign_to_button
        expect(icon_type_exists?("Discussion")).to be true
        expect(tray_header.text).to eq("Discussion 1")
      end

      it "saves and shows override updates when tray reaccessed" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"

        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        update_available_date(0, "12/27/2024")
        update_available_time(0, "8:00 AM")

        click_save_button
        keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner

        keep_trying_until { expect(item_tray_exists?).to be_truthy }

        expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2024")
        expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
      end

      it "does not show due date inputs on ungraded discussion" do
        dt = @course.discussion_topics.create!(
          title: "Ungraded Discussion",
          discussion_type: "threaded",
          posted_at: "2024-02-09 16:32:34",
          user: @teacher
        )
        get "/courses/#{@course.id}/discussion_topics/#{dt.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner
        expect(module_item_assign_to_card.last).not_to contain_css(due_date_input_selector)
      end

      it "shows due date inputs on graded discussion" do
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
          assignment:
        )
        get "/courses/#{@course.id}/discussion_topics/#{dt.id}"
        Discussion.click_assign_to_button
        wait_for_assign_to_tray_spinner
        expect(module_item_assign_to_card.last).to contain_css(due_date_input_selector)
      end
    end
  end
end
