# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "pages/discussions_index_page"
require_relative "../helpers/discussions_common"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/items_assign_to_tray"
require_relative "../../helpers/selective_release_common"

describe "discussions index" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ItemsAssignToTray
  include DiscussionsCommon
  include SelectiveReleaseCommon

  context "as a teacher" do
    discussion1_title = "Meaning of life"
    discussion2_title = "Meaning of the universe"

    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
      course_with_student(course: @course, active_enrollment: true)

      # Discussion attributes: title, message, delayed_post_at, user
      @discussion1 = @course.discussion_topics.create!(
        title: discussion1_title,
        message: "Is it really 42?",
        user: @teacher,
        pinned: false
      )
      @discussion2 = @course.discussion_topics.create!(
        title: discussion2_title,
        message: "Could it be 43?",
        delayed_post_at: 1.day.from_now,
        user: @teacher,
        locked: true,
        pinned: false
      )

      @discussion1.discussion_entries.create!(user: @student, message: "I think I read that somewhere...")
      @discussion1.discussion_entries.create!(user: @student, message: ":eyeroll:")
    end

    def login_and_visit_course(teacher, course)
      user_session(teacher)
      DiscussionsIndex.visit(course)
    end

    def create_course_and_discussion(opts)
      opts.reverse_merge!({ locked: false, pinned: false })
      course = course_factory(active_all: true)
      discussion = course.discussion_topics.create!(
        title: opts[:title],
        message: opts[:message],
        user: @teacher,
        locked: opts[:locked],
        pinned: opts[:pinned]
      )
      [course, discussion]
    end

    it "discussions can be filtered", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.select_filter("Unread")

      # Attempt to make this test less brittle. It's doing client side filtering
      # with a debounce function, so we need to give it time to perform the filtering
      expect(DiscussionsIndex.discussion(discussion1_title)).to be_displayed
      expect(DiscussionsIndex.discussion_group("Closed for Comments"))
        .not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion2_title))
    end

    it "search by title works correctly", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.enter_search(discussion1_title)

      # Attempt to make this test less brittle. It's doing client side filtering
      # with a debounce function, so we need to give it time to perform the filtering
      expect(DiscussionsIndex.discussion(discussion1_title)).to be_displayed
      expect(DiscussionsIndex.discussion_group("Closed for Comments"))
        .not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion2_title))
    end

    it "clicking the Add Discussion button redirects to new discussion page", priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect_new_page_load { DiscussionsIndex.click_add_discussion }
      expect(driver.current_url).to include(DiscussionsIndex.new_discussion_url)
    end

    it "clicking the publish button changes the published status", priority: "1" do
      # Cannot use @discussion[12] here because unpublish requires there to be no posts
      course, discussion = create_course_and_discussion(
        title: "foo",
        message: "foo"
      )
      expect(discussion.published?).to be true
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_publish_button("foo")
      wait_for_ajaximations
      discussion.reload
      expect(discussion.published?).to be false
    end

    it "clicking the subscribe button changes the subscribed status", priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect(@discussion1.subscribed?(@teacher)).to be true
      DiscussionsIndex.click_subscribe_button(discussion1_title)
      wait_for_ajaximations
      expect(@discussion1.subscribed?(@teacher)).to be false
    end

    it "discussion can be moved between groups using Pin menu item", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_pin_menu_option(discussion1_title)
      group = DiscussionsIndex.discussion_group("Pinned Discussions")
      expect(group).to include_text(discussion1_title)
      @discussion1.reload
      expect(@discussion1.pinned).to be true
    end

    it "unpinning an unlocked discussion goes to the regular bin" do
      course, discussion = create_course_and_discussion(
        title: "Discussion about aaron",
        message: "Aaron is aaron",
        locked: false,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_pin_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Discussions")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.pinned).to be false
    end

    it "unpinning a locked discussion goes to the locked bin" do
      course, discussion = create_course_and_discussion(
        title: "Discussion about landon",
        message: "Landon is landon",
        locked: true,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_pin_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Closed for Comments")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.pinned).to be false
    end

    it "discussion can be moved to Closed For Comments group using menu item", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion1_title)
      group = DiscussionsIndex.discussion_group("Closed for Comments")
      expect(group).to include_text(discussion1_title)
      @discussion1.reload
      expect(@discussion1.locked).to be true
    end

    it "closing a pinned discussion stays pinned" do
      course, discussion = create_course_and_discussion(
        title: "Discussion about steven",
        message: "Steven is steven",
        locked: false,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Pinned Discussions")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.locked).to be true
    end

    it 'opening an unpinned discussion moves to "regular"' do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion2_title)
      group = DiscussionsIndex.discussion_group("Discussions")
      expect(group).to include_text(discussion1_title)
      @discussion2.reload
      expect(@discussion2.locked).to be false
    end

    it "clicking the discussion goes to the discussion page", priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect_new_page_load { DiscussionsIndex.click_on_discussion(discussion1_title) }
      expect(driver.current_url).to include(DiscussionsIndex.individual_discussion_url(@discussion1))
    end

    it "a discussion can be deleted by using Delete menu item and modal", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_delete_menu_option(discussion1_title)
      DiscussionsIndex.click_delete_modal_confirm
      expect(f("#content")).not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion1_title))
      expect(DiscussionTopic.where(title: discussion1_title).first.workflow_state).to eq "deleted"
    end

    it "a discussion can be duplicated by using Duplicate menu item", priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_duplicate_menu_option(discussion1_title)
      expect(DiscussionsIndex.discussion(discussion1_title + " Copy")).to be_displayed
    end

    it "pill on announcement displays correct number of unread replies", priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect(DiscussionsIndex.discussion_unread_pill(discussion1_title)).to eq "2"
    end

    it "allows teachers to edit discussions settings" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_discussion_settings_button
      DiscussionsIndex.click_create_discussions_checkbox
      DiscussionsIndex.submit_discussion_settings
      wait_for_stale_element(".discussion-settings-v2-spinner-container")
      @course.reload
      expect(@course.allow_student_discussion_topics).to be false
    end

    context "differentiated modules assignToTray" do
      # Since the itemAssignTo Tray contains all of the logic for setting
      # assignment values. We only need to test that the correct overrides are
      # Displayed from the index page

      before do
        differentiated_modules_on
        @student1 = student_in_course(course: @course, active_all: true).user
        @student2 = student_in_course(course: @course, active_all: true).user
        @course_section = @course.course_sections.create!(name: "section alpha")
        @course_section_2 = @course.course_sections.create!(name: "section Beta")
      end

      it "displays module_override correctly" do
        graded_discussion = create_graded_discussion(@course)
        module1 = @course.context_modules.create!(name: "Module 1")
        graded_discussion.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        override = module1.assignment_overrides.create!
        override.assignment_override_students.create!(user: @student1)

        login_and_visit_course(@teacher, @course)
        DiscussionsIndex.click_assign_to_menu_option(graded_discussion.title)

        expect(module_item_assign_to_card.count).to eq 1
        expect(module_item_assign_to_card[0].find_all(assignee_selected_option_selector).map(&:text)).to eq ["User"]
        expect(inherited_from.last.text).to eq("Inherited from #{module1.name}")
      end

      it "displays ungraded availability correctly" do
        available_from_date = "Tue, 23 Apr 2024 18:28:42.003452000 UTC +00:00"

        @ungraded_discussion_with_dates = @course.discussion_topics.create!(
          title: "ungraded overrides",
          message: "Could it be 43?",
          user: @teacher,
          delayed_post_at: available_from_date
        )
        login_and_visit_course(@teacher, @course)
        DiscussionsIndex.click_assign_to_menu_option(@ungraded_discussion_with_dates.title)

        expect(item_tray_exists?).to be_truthy
        expect(module_item_assign_to_card.count).to eq 1
        expect(selected_assignee_options.first.find("span").text).to eq "Everyone"
        expect(assign_to_due_date(0).attribute("value")).to eq("Apr 23, 2024")
        expect(assign_to_due_time(0).attribute("value")).to eq("6:28 PM")

        expect(assign_to_available_from_date(0).attribute("value")).to eq("")
        expect(assign_to_available_from_time(0).attribute("value")).to eq("")
      end

      it "displays graded discussion overrides correctly" do
        graded_discussion = create_graded_discussion(@course)

        # Create overrides
        # Card 1 = ["Everyone else"], Set by: only_visible_to_overrides: false

        # Card 2
        graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section.id)

        # Card 3
        graded_discussion.assignment.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section_2.id)

        # Card 4
        graded_discussion.assignment.assignment_overrides.create!(set_type: "ADHOC")
        graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student1)
        graded_discussion.assignment.assignment_overrides.last.assignment_override_students.create!(user: @student2)

        login_and_visit_course(@teacher, @course)
        DiscussionsIndex.click_assign_to_menu_option(graded_discussion.title)

        # Check that displayed cards and overrides are correct
        expect(module_item_assign_to_card.count).to eq 4

        displayed_overrides = module_item_assign_to_card.map do |card|
          card.find_all(assignee_selected_option_selector).map(&:text)
        end

        expected_overrides = generate_expected_overrides(graded_discussion.assignment)
        expect(displayed_overrides).to match_array(expected_overrides)
      end

      it "does not render assign to tray on group discussions index" do
        group = @course.groups.create!(name: "Group 1")
        discussion = group.discussion_topics.create!(title: "group topic")
        user_session(@teacher)
        get("/groups/#{group.id}/discussion_topics/")
        wait_for_ajaximations
        DiscussionsIndex.discussion_menu(discussion.title).click
        expect(DiscussionsIndex.manage_discussions_menu).to include_text("Delete")
        expect(DiscussionsIndex.manage_discussions_menu).not_to include_text("Assign To")
      end

      it "does not render assign to tray in course context with ungraded group discussions index" do
        group = @course.groups.create!(name: "Group 1")
        discussion = @course.discussion_topics.create!(title: "group topic", group_category: group.group_category)
        user_session(@teacher)
        get("/courses/#{@course.id}/discussion_topics/")
        wait_for_ajaximations
        DiscussionsIndex.discussion_menu(discussion.title).click
        expect(DiscussionsIndex.manage_discussions_menu).to include_text("Delete")
        expect(DiscussionsIndex.manage_discussions_menu).not_to include_text("Assign To")
      end

      it "does not show the option when the user does not have the moderate_forum permission" do
        discussion = create_graded_discussion(@course)
        login_and_visit_course(@teacher, @course)
        DiscussionsIndex.discussion_menu(discussion.title).click
        expect(DiscussionsIndex.manage_discussions_menu).to include_text("Assign To")

        RoleOverride.create!(context: @course.account, permission: "moderate_forum", role: teacher_role, enabled: false)
        login_and_visit_course(@teacher, @course)
        DiscussionsIndex.discussion_menu(discussion.title).click
        expect(DiscussionsIndex.manage_discussions_menu).not_to include_text("Assign To")
      end
    end
  end
end
