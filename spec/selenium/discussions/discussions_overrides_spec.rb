# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../helpers/discussions_common"
require_relative "../helpers/assignment_overrides"
require_relative "../helpers/items_assign_to_tray"

describe "discussions overrides" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include DiscussionsCommon
  include ItemsAssignToTray

  before do
    course_with_teacher_logged_in
    @new_section = @course.course_sections.create!(name: "New Section")
    @assignment = @course.assignments.create!(name: "assignment", assignment_group: @assignment_group)
    @discussion_topic = @course.discussion_topics.create!(user: @teacher,
                                                          title: "Discussion 1",
                                                          message: "Discussion with multiple due dates",
                                                          assignment: @assignment)
  end

  describe "set overrides" do
    around do |example|
      Timecop.freeze(Time.zone.local(2016, 12, 15, 10, 0, 0), &example)
    end

    before do
      default_due_at = Time.zone.now.advance(days: 1).round
      override_due_at = Time.zone.now.advance(days: 2).round
      @assignment.due_at = default_due_at
      add_user_specific_due_date_override(@assignment, due_at: override_due_at, section: @new_section)
      @discussion_topic.save!
      @default_due_at_time = format_time_for_view(default_due_at)
      @override_due_at_time = format_time_for_view(override_due_at)
    end

    it "shows course pace notice when expanding grades in a course with pacing on" do
      skip "Will be fixed in VICE-5209"
      @course.enable_course_paces = true
      @course.save!
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
      fj("a:contains('Show Due Dates')").click
      expect(f('[data-testid="CoursePacingNotice"]')).to be_displayed
    end

    it "toggles between due dates", priority: "2" do
      skip "Will be fixed in VICE-5209"
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
      f(" .toggle_due_dates").click
      wait_for_ajaximations
      expect(f(".discussion-topic-due-dates")).to be_present
      expect(f(".discussion-topic-due-dates tbody tr td:nth-of-type(1)").text).to include(@default_due_at_time)
      expect(f(".discussion-topic-due-dates tbody tr td:nth-of-type(2)").text).to include("Everyone else")
      expect(f(".discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(1)").text)
        .to include(@override_due_at_time)
      expect(f(".discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(2)").text).to include("New Section")
      f(".toggle_due_dates").click
      wait_for_ajaximations
      expect(f(".discussion-topic-due-dates")).to be_present
    end

    context "outside discussions page" do
      before do
        @default_due = format_date_for_view(Time.zone.now.advance(days: 1))
        @override_due = format_date_for_view(Time.zone.now.advance(days: 2))
      end

      it "shows due dates in mouse hover in the assignments index page", priority: "2" do
        get "/courses/#{@course.id}/assignments"
        hover_text = "Everyone else\n#{@default_due}\nNew Section\n#{@override_due}"
        hover f(".assignment-date-due .vdd_tooltip_link")
        expect(f(".ui-tooltip-content")).to include_text(hover_text)
      end

      it "lists discussions in the syllabus", priority: "2" do
        get "/courses/#{@course.id}/assignments/syllabus"
        expect(f("#syllabus tbody tr:nth-of-type(1) .day_date").text).to include(@default_due)
        expect(f("#syllabus tbody tr:nth-of-type(1)").text).to include(@discussion_topic.title)
        expect(f("#syllabus tbody tr:nth-of-type(2) .day_date").text).to include(@override_due)
        expect(f("#syllabus tbody tr:nth-of-type(2)").text).to include(@discussion_topic.title)
        expect(f("#syllabus tbody tr:nth-of-type(2).detail_list td .special_date_title").text).to include(@new_section.name)
      end

      it "lists the discussions in course dashboard page", priority: "2" do
        get "/courses/#{@course.id}"
        expect(f(".coming_up .event a").text).to eq("#{@discussion_topic.title}\nMultiple Due Dates")
      end

      it "lists the discussions in main dashboard page", priority: "2" do
        course_with_admin_logged_in(course: @course)
        get ""
        element = f(".coming_up .event a")
        wait_for_ajaximations
        keep_trying_until { expect(element.text).to eq("#{@discussion_topic.title}\n#{course_factory.short_name}\nMultiple Due Dates") }
      end
    end
  end

  describe "Differentiation Tags" do
    before do
      Account.site_admin.enable_feature! :discussion_create
      Account.site_admin.enable_feature! :react_discussions_post
      course_with_teacher_logged_in
      @course.account.enable_feature!(:assign_to_differentiation_tags)
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: true }
        a.save!
      end
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
      @group_category = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
      @group_category.create_groups(1)
      @differentiation_tag_group_1 = @group_category.groups.first_or_create
      @differentiation_tag_group_1.add_user(@student1)
      @assignment = @course.assignments.create!(name: "assignment", assignment_group: @assignment_group)
      @discussion_topic = @course.discussion_topics.create!(user: @teacher,
                                                            title: "Discussion 1",
                                                            message: "Discussion with multiple due dates",
                                                            assignment: @assignment)
      @assignment.assignment_overrides.create!(set: @differentiation_tag_group_1)
      @assignment.update!(only_visible_to_overrides: true)
    end

    it "shows convert override message when diff tags setting disabled" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}/edit"
      wait_for_ajaximations
      expect(element_exists?(convert_override_alert_selector)).to be_truthy
    end

    it "clicking convert overrides button converts the override and refreshes the cards" do
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}/edit"
      wait_for_ajaximations
      expect(f(assignee_selected_option_selector).text).to include(@differentiation_tag_group_1.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      expect(f(assignee_selected_option_selector).text).to include(@student1.name)
    end

    it "clicking convert overrides button converts overrides and refreshes the cards" do
      gc = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
      gc.create_groups(1)
      differentiation_tag_group_2 = gc.groups.first_or_create
      differentiation_tag_group_2.add_user(@student2)
      @assignment.assignment_overrides.create!(set: differentiation_tag_group_2)
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: false }
        a.save!
      end
      get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}/edit"
      wait_for_ajaximations
      overrides = ff(assignee_selected_option_selector)
      expect(overrides[0].text).to include(@differentiation_tag_group_1.name)
      expect(overrides[1].text).to include(differentiation_tag_group_2.name)
      f(convert_override_button_selector).click
      wait_for_ajaximations
      converted_overrides = ff(assignee_selected_option_selector)
      expect(converted_overrides[0].text).to include(@student2.name)
      expect(converted_overrides[1].text).to include(@student1.name)
    end
  end
end
