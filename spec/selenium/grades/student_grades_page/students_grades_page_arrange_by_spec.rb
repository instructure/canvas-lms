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

require_relative "../../helpers/gradebook_common"
require_relative "../setup/gradebook_setup"
require_relative "../pages/student_grades_page"

describe "Student Gradebook - Arrange By" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  let(:due_date_order) { [@assignment0.title, @quiz.title, @discussion.title, @assignment1.title] }
  let(:title_order) { [@quiz.title, @assignment1.title, @assignment0.title, @discussion.title] }
  let(:module_order) { [@quiz.title, @assignment0.title, @assignment1.title, @discussion.title] }
  let(:assign_group_order) { [@assignment0.title, @discussion.title, @quiz.title, @assignment1.title] }

  describe "Arrange By dropdown" do
    before :once do
      course_with_student(name: "Student", active_all: true)

      # create multiple assignments in different modules and assignment groups
      group0 = @course.assignment_groups.create!(name: "Messi Physics Group")
      group1 = @course.assignment_groups.create!(name: "Ronaldo Chem Group")

      @assignment0 = @course.assignments.create!(
        name: "Physics Alpha Assign",
        due_at: Time.now.utc + 3.days,
        assignment_group: group0
      )

      @quiz = @course.quizzes.create!(
        title: "Chem Alpha Quiz",
        due_at: Time.now.utc + 5.days,
        assignment_group_id: group1.id
      )
      @quiz.publish!

      @discussion_assignment = @course.assignments.create!(
        due_at: Time.now.utc + 5.days + 1.hour,
        assignment_group: group0
      )

      @discussion = @course.discussion_topics.create!(
        assignment: @discussion_assignment,
        title: "Physics Beta Discussion"
      )

      @assignment1 = @course.assignments.create!(
        name: "Chem Beta Assign",
        due_at: Time.now.utc + 6.days,
        assignment_group: group1
      )

      module0 = ContextModule.create!(name: "Alpha Mod", context: @course)
      module1 = ContextModule.create!(name: "Beta Mod", context: @course)

      module0.content_tags.create!(context: @course, content: @quiz.assignment, tag_type: "context_module")
      module0.content_tags.create!(context: @course, content: @assignment0, tag_type: "context_module")
      module1.content_tags.create!(context: @course, content: @assignment1, tag_type: "context_module")
      module1.content_tags.create!(context: @course, content: @discussion_assignment, tag_type: "context_module")
    end

    context "when restrict_quantitative_data is OFF" do
      it "sorts properly" do
        user_session(@student)
        get "/courses/#{@course.id}/grades/#{@student.id}"
        click_option("#assignment_sort_order_select_menu", "Name")
        expect_new_page_load { f("#apply_select_menus").click }

        current_list = (ff("#grades_summary tr a").reject { |a| a.text.empty? }).collect(&:text)
        expect(current_list).to eq title_order

        click_option("#assignment_sort_order_select_menu", "Due Date")
        expect_new_page_load { f("#apply_select_menus").click }

        current_list = (ff("#grades_summary tr a").reject { |a| a.text.empty? }).collect(&:text)
        expect(current_list).to eq due_date_order

        click_option("#assignment_sort_order_select_menu", "Module")
        expect_new_page_load { f("#apply_select_menus").click }

        current_list = (ff("#grades_summary tr a").reject { |a| a.text.empty? }).collect(&:text)
        expect(current_list).to eq module_order

        click_option("#assignment_sort_order_select_menu", "Assignment Group")
        expect_new_page_load { f("#apply_select_menus").click }

        current_list = (ff("#grades_summary tr a").reject { |a| a.text.empty? }).collect(&:text)
        expect(current_list).to eq assign_group_order
      end

      it "persists" do
        user_session(@student)
        get "/courses/#{@course.id}/grades/#{@student.id}"
        click_option("#assignment_sort_order_select_menu", "Name")
        expect_new_page_load { f("#apply_select_menus").click }
        refresh_page
        current_list = (ff("#grades_summary tr a").reject { |a| a.text.empty? }).collect(&:text)
        expect(current_list).to eq title_order
      end
    end

    context "when user is quantitative data restricted" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!
      end

      it "can toggle between different sorting orders" do
        user_session(@student)
        get "/courses/#{@course.id}/grades/#{@student.id}"
        # sorted by due date by default
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Due Date"
        current_list = ff("a[data-testid='assignment-link']").collect(&:text)
        expect(current_list).to eq due_date_order

        f("label[for='assignment_sort_order_select_menu']").click
        fj("[data-testid='select-menu-option']:contains('Assignment Group')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Assignment Group"
        current_list = ff("a[data-testid='assignment-link']").collect(&:text)
        expect(current_list).to eq assign_group_order

        f("label[for='assignment_sort_order_select_menu']").click
        fj("[data-testid='select-menu-option']:contains('Name')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Name"
        current_list = ff("a[data-testid='assignment-link']").collect(&:text)
        expect(current_list).to eq title_order

        f("label[for='assignment_sort_order_select_menu']").click
        fj("[data-testid='select-menu-option']:contains('Module')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Module"
        current_list = ff("a[data-testid='assignment-link']").collect(&:text)
        expect(current_list).to eq module_order
      end

      it "persists for user after changing preferred order" do
        user_session(@student)
        get "/courses/#{@course.id}/grades/#{@student.id}"
        f("label[for='assignment_sort_order_select_menu']").click
        fj("[data-testid='select-menu-option']:contains('Assignment Group')").click
        fj("button:contains('Apply')").click
        wait_for_ajaximations
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Assignment Group"
        refresh_page
        expect(f("label[for='assignment_sort_order_select_menu'] input").attribute("value")).to eq "Assignment Group"
      end
    end
  end
end
