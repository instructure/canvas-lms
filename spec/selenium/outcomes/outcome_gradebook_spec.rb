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

require_relative "../grades/pages/gradebook_page"
require_relative "../grades/setup/gradebook_setup"
require_relative "../helpers/gradebook_common"

describe "outcome gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
      @outcome1 = outcome_model(context: @course, title: "outcome1")
      @outcome2 = outcome_model(context: @course, title: "outcome2")
      show_sections_filter(@teacher)
    end

    before do
      user_session(@teacher)
    end

    after do
      clear_local_storage
    end

    def select_learning_mastery
      f(".assignment-gradebook-container .gradebook-menus button").click
      f('span[data-menu-item-id="learning-mastery"]').click
    end

    def section_filter
      f('[data-component="SectionFilter"] input')
    end

    def select_section(menu_item_name)
      section_filter.click
      wait_for_animations
      fj("[role=\"option\"]:contains(\"#{menu_item_name}\")").click
      wait_for_ajaximations
    end

    def mean_values
      f("button[data-testid='lmgb-course-calc-dropdown']").click
      fj("[role=\"menuitemradio\"]:contains(\"Course average\")").click
      wait_for_ajax_requests
      selected_values
    end

    def median_values
      f("button[data-testid='lmgb-course-calc-dropdown']").click
      fj("[role=\"menuitemradio\"]:contains(\"Course median\")").click
      wait_for_ajax_requests
      selected_values
    end

    def selected_values
      ff(".outcome-gradebook-container .headerRow_1 .outcome-score").map(&:text)
    end

    def nth_mastery_score(index)
      ff(".outcome-gradebook-container .viewport_1 .outcome-score")[index].text
    end

    def selected_values_colors
      ff(".outcome-gradebook-container .headerRow_1 .outcome-result").map do |r|
        CanvasColor::Color.parse(
          *
            r
              .style("background-color")
              .match(/rgba\((.*), (.*), (.*), .*/)
              .captures
              .map(&:to_i)
        ).to_s
      end
    end

    def student_names
      ff(".outcome-student-cell-content .student-grades-list").map { |cell| cell.text.split("\n")[0] }
    end

    it "is not visible by default" do
      Gradebook.visit(@course)
      f(".assignment-gradebook-container .gradebook-menus button").click
      expect(f("#content")).not_to contain_css('span[data-menu-item-id="learning-mastery"]')
    end

    context "when enabled" do
      before :once do
        Account.default.set_feature_flag!("outcome_gradebook", "on")
      end

      it "is visible" do
        Gradebook.visit(@course)
        Gradebook.gradebook_menu_element.click
        expect(f('span[data-menu-item-id="learning-mastery"]')).not_to be_nil
        f('span[data-menu-item-id="learning-mastery"]').click

        expect(f(".outcome-gradebook-container")).not_to be_nil
      end

      def three_students
        expect(ff(".outcome-student-cell-content")).to have_size 3
      end

      def no_students
        expect(f("#application")).not_to contain_css(".outcome-student-cell-content")
      end

      def two_outcomes
        expect(ff(".outcome-gradebook-container .headers_1 .slick-header-column")).to have_size 2
      end

      def no_outcomes
        expect(f(".outcome-gradebook-container .headers_1")).not_to contain_css(".slick-header-column")
      end

      def toggle_lmgb_filter_dropdown
        f('[data-component="lmgb-student-filter-trigger"]').click
      end

      def toggle_no_results_students
        toggle_lmgb_filter_dropdown
        f('[data-component="lmgb-student-filter-unassessed-students"]').click
        wait_for_ajax_requests
      end

      it "filter out students without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        no_students

        toggle_no_results_students
        three_students

        toggle_no_results_students
        no_students
      end

      it "filter out outcomes without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        two_outcomes

        f("#no_results_outcomes").click
        no_outcomes

        f("#no_results_outcomes").click
        two_outcomes
      end

      it "filter out outcomes and students without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        two_outcomes
        no_students

        toggle_no_results_students
        f("#no_results_outcomes").click
        no_outcomes
        three_students

        f("#no_results_outcomes").click
        two_outcomes
        three_students
      end

      it "outcomes without results filter preserved after page refresh" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        wait_for_ajax_requests

        expect(f("#no_results_outcomes").selected?).to be false

        f("#no_results_outcomes").click
        refresh_page

        expect(f("#no_results_outcomes").selected?).to be true
      end

      it "outcomes popover renders when hovering over outcome column header" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        wait_for_ajax_requests

        # Make the popover appear by selecting first outcome column header
        column_header = ff(".slick-column-name")[0]
        driver.action.move_to(column_header).perform

        expect(f(".outcome-details")).not_to be_nil
      end

      def result(user, alignment, score, opts = {})
        LearningOutcomeResult.create!(user:, alignment:, score:, context: @course, **opts)
      end

      context "with results" do
        before(:once) do
          align1 = @outcome1.align(@assignment, @course)
          align2 = @outcome2.align(@assignment, @course)
          result(@student_1, align1, 5)
          result(@student_2, align1, 3)
          result(@student_3, align1, 0)
          result(@student_1, align2, 4)
          result(@student_2, align2, 2)
          result(@student_3, align2, 1)
        end

        it "keeps course mean after outcomes without results filter enabled" do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # mean
          means = selected_values
          expect(means).to contain_exactly("2.33", "2.67")

          f("#no_results_outcomes").click
          wait_for_ajax_requests

          # mean
          means = selected_values
          expect(means).to contain_exactly("2.33", "2.67")
        end

        it "displays course mean and median" do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # mean
          averages = selected_values
          expect(averages).to contain_exactly("2.33", "2.67")

          # median
          medians = median_values
          expect(medians).to contain_exactly("2", "3")

          # switch to first section
          select_section(@course.course_sections.first.name)
          wait_for_ajax_requests

          # median
          medians = selected_values
          expect(medians).to contain_exactly("2.5", "2.5")

          # switch to second section
          select_section(@course.course_sections.second.name)
          wait_for_ajax_requests

          # refresh page
          refresh_page

          # should remain on second section, with mean
          means = selected_values
          expect(means).to contain_exactly("2", "3")
        end

        # test added because of OUT-6176
        # Changing from "mean" -> "median" -> "mean" would result in a 404 page
        # This tests makes sure no errors happen when doing this
        it "can alternate from mean to median and back to mean" do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # Confirm that "mean" values are shown
          averages = selected_values
          expect(averages).to contain_exactly("2.33", "2.67")

          # Switch to "median" values
          medians = median_values
          expect(medians).to contain_exactly("2", "3")

          averages = mean_values
          expect(averages).to contain_exactly("2.33", "2.67")
        end

        it "outcome ordering persists accross page refresh" do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests
          column_headers = ff(".slick-column-name")

          expect(column_headers.map(&:text)).to eq ["outcome1", "outcome2"]
          expect(ff(".headerRow_1 .outcome-score").map(&:text)).to eq ["2.67", "2.33"]

          # Reorder the column headers
          driver.action.drag_and_drop(column_headers[1], column_headers[0]).perform
          outcomes = ff(".slick-column-name").map(&:text)
          expect(outcomes).to eq ["outcome2", "outcome1"]
          expect(ff(".headerRow_1 .outcome-score").map(&:text)).to eq ["2.33", "2.67"]

          refresh_page

          outcomes = ff(".slick-column-name").map(&:text)
          expect(outcomes).to eq ["outcome2", "outcome1"]
          expect(ff(".headerRow_1 .outcome-score").map(&:text)).to eq ["2.33", "2.67"]
        end

        context "outcome with average calculation method" do
          before(:once) do
            @outcome3 = outcome_model(context: @course, title: "outcome3", calculation_method: "latest")
            @outcome3.save!
            align2 = @outcome3.align(@second_assignment, @course)
            align3 = @outcome3.align(@third_assignment, @course)
            result(@student_1, align2, 4)
            result(@student_1, align3, 1)
            # below is needed to avoid test flakiness
            @course.enrollments.find_by(user_id: @student_2.id).deactivate
            @course.enrollments.find_by(user_id: @student_3.id).deactivate
            LearningOutcomeResult.find_by(learning_outcome_id: @outcome1.id).destroy
            LearningOutcomeResult.find_by(learning_outcome_id: @outcome2.id).destroy
            @outcome1.destroy
            @outcome2.destroy
          end

          it "calculates properly mastery score using average method" do
            @outcome3.calculation_method = "average"
            @outcome3.save!

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            # student's mastery score for outcome 3 calculated with "average" method
            student_mastery_score = nth_mastery_score(0)
            expect(student_mastery_score).to eq("2.5")
          end

          it "recalculates properly outcome score using average method" do
            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            # student's mastery score for outcome3 calculated with "latest" method
            student_mastery_score = nth_mastery_score(0)
            expect(student_mastery_score).to eq("1")

            # change calculation method to average
            @outcome3.calculation_method = "average"
            @outcome3.save!

            # refresh page
            refresh_page

            # student's mastery score for outcome3 calculated with "average" method
            student_mastery_score = nth_mastery_score(0)
            expect(student_mastery_score).to eq("2.5")
          end
        end

        context "inactive/concluded LMGB filters" do
          it "correctly displays inactive enrollments when the filter option is selected" do
            StudentEnrollment.find_by(user_id: @student_1.id).deactivate

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_2.name, @student_3.name]
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-inactive-enrollments"]').click
            wait_for_ajax_requests

            active_and_inactive_students = active_students.unshift(@student_1.name)
            expect(student_names.sort).to eq(active_and_inactive_students)
          end

          it "displays inactive tag for inactive enrollments" do
            StudentEnrollment.find_by(user_id: @student_1.id).deactivate

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-inactive-enrollments"]').click
            wait_for_ajax_requests

            tags = ff(".outcome-student-cell-content .label")
            expect(tags.size).to eq(1)
            expect(tags.first.text).to eq("inactive")
          end

          it "correctly displays concluded enrollments when the filter option is selected" do
            StudentEnrollment.find_by(user_id: @student_1.id).conclude

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_2.name, @student_3.name]
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-concluded-enrollments"]').click
            wait_for_ajax_requests

            active_and_concluded_students = active_students.unshift(@student_1.name)
            expect(student_names.sort).to eq(active_and_concluded_students)
          end

          it "displays concluded tag for concluded enrollments" do
            StudentEnrollment.find_by(user_id: @student_1.id).conclude

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-concluded-enrollments"]').click
            wait_for_ajax_requests

            tags = ff(".outcome-student-cell-content .label")
            expect(tags.size).to eq(1)
            expect(tags.first.text).to eq("concluded")
          end

          it "correctly displays unassessed students when the filter option is selected" do
            student_4 = User.create!(name: "Unassessed Student")
            student_4.register!
            @course.enroll_student(student_4)

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name]
            student_names = ff(".outcome-student-cell-content").map { |cell| cell.text.split("\n")[0] }
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-unassessed-students"]').click
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name, student_4.name]
            student_names = ff(".outcome-student-cell-content").map { |cell| cell.text.split("\n")[0] }
            expect(student_names.sort).to eq(active_students.sort)
          end

          it "retains focus on filter button after a filter is chosen" do
            student_4 = User.create!(name: "Unassessed Student")
            student_4.register!
            @course.enroll_student(student_4)

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-unassessed-students"]').click
            wait_for_ajax_requests
            expect(ff(".outcome-student-cell-content").map(&:text)).to include(a_string_matching(/Unassessed Student/))
            check_element_has_focus(f('button[data-component="lmgb-student-filter-trigger"]'))
          end
        end

        context "with learning mastery scales enabled" do
          before(:once) do
            @rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
            @rating2 = OutcomeProficiencyRating.new(description: "worst", points: 0, mastery: false, color: "ff0000")
            @proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [@rating1, @rating2], context: Account.default)
            @calculation_method = OutcomeCalculationMethod.create!(context: Account.default, calculation_method: "latest")
            @second_outcome_assignment = @course.assignments.create!(
              title: "Outcome 1 Second Assignment",
              grading_type: "points",
              points_possible: 10,
              submission_types: "online_text_entry",
              due_at: 2.days.ago
            )
            align3 = @outcome1.align(@second_outcome_assignment, @course)
            result(@student_1, align3, 0)
            result(@student_2, align3, 1)
            result(@student_3, align3, 2)
          end

          it "Displays the mastery scales and proficiency calculations once enabled" do
            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("1.58", "2.33")

            # median
            medians = median_values
            expect(medians).to contain_exactly("1.7", "2")

            Account.default.set_feature_flag!("account_level_mastery_scales", "on")
            # refresh page
            refresh_page

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("3.33", "7.78")

            # median
            medians = median_values
            expect(medians).to contain_exactly("3.33", "6.67")
          end

          it "Displays changes to the mastery scales and proficiency calculations" do
            Account.default.set_feature_flag!("account_level_mastery_scales", "on")

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("3.33", "7.78")

            # median
            medians = median_values
            expect(medians).to contain_exactly("3.33", "6.67")

            # Update the ratings points, and use the highest calculation method so averages will be over 100
            @rating1.points = 100
            @rating2.points = 10
            @calculation_method.calculation_method = "highest"
            @calculation_method.save!
            @proficiency.save!

            # refresh page
            refresh_page

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("111.11", "77.78")

            # median
            medians = median_values
            expect(medians).to contain_exactly("100", "66.67")
          end

          it "Displays the course level outcome values when FF is turned off" do
            Account.default.set_feature_flag!("account_level_mastery_scales", "on")

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("3.33", "7.78")

            # median
            medians = median_values
            expect(medians).to contain_exactly("3.33", "6.67")

            Account.default.set_feature_flag!("account_level_mastery_scales", "off")

            # refresh page
            refresh_page

            # mean
            averages = selected_values
            expect(averages).to contain_exactly("1.58", "2.33")

            # median
            medians = median_values
            expect(medians).to contain_exactly("1.7", "2")
          end
        end
      end

      context "Account Level Mastery Scales" do
        before(:once) do
          outcome_criterion = LearningOutcome.default_rubric_criterion
          outcome_criterion[:ratings][1][:points] = 4
          outcome_criterion[:mastery_points] = 4

          outcome = LearningOutcome.create!(context: @course, title: "Outcome with individual ratings", rubric_criterion: outcome_criterion)

          proficiency = OutcomeProficiency.new(context: @course)
          proficiency.replace_ratings(OutcomeProficiency.default_ratings)
          proficiency.save!

          OutcomeCalculationMethod.create!(context: @course, calculation_method: "highest")

          assignment = @course.assignments.create!(
            title: "Outcome Assignment",
            grading_type: "points",
            points_possible: 4,
            submission_types: "online_text_entry",
            due_at: 2.days.ago
          )

          alignment = outcome.align(assignment, @course)
          result(@student_1, alignment, 3)
        end

        it "Displays mastery achieved if Account Level Mastery Scales FF is enabled" do
          Account.default.set_feature_flag!("account_level_mastery_scales", "on")
          Account.default.set_feature_flag!("improved_outcomes_management", "on")

          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          expect(selected_values_colors).to contain_exactly("#0B874B")
        end

        it "Displays mastery not achieved if Account Level Mastery Scales FF is disabled" do
          Account.default.set_feature_flag!("account_level_mastery_scales", "off")
          Account.default.set_feature_flag!("improved_outcomes_management", "on")

          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          expect(selected_values_colors).to contain_exactly("#FC5E13")
        end
      end

      context "with non-scoring results" do
        before(:once) do
          align1 = @outcome1.align(@assignment, @course)
          align2 = @outcome2.align(@assignment, @course)
          result(@student_1, align1, 5, hide_points: true)
          result(@student_2, align1, 3, hide_points: true)
          result(@student_3, align1, 0, hide_points: true)
          result(@student_1, align2, 4, hide_points: true)
          result(@student_2, align2, 2, hide_points: true)
          result(@student_3, align2, 1)
        end

        it "displays rating description for course mean" do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # all but one result are non-scoring, so we display score
          expect(ff(".outcome-gradebook-container .headerRow_1 .outcome-score")).to have_size 1
          expect(ff(".outcome-gradebook-container .headerRow_1 .outcome-score").first.text).to eq "2.33"
          # all results are non-scoring
          expect(ff(".outcome-gradebook-container .headerRow_1 .outcome-description")).to have_size 1
          expect(ff(".outcome-gradebook-container .headerRow_1 .outcome-description").first.text).to eq "Near Mastery"
        end
      end

      it "allows showing only a certain section" do
        Gradebook.visit(@course)
        select_learning_mastery

        toggle_no_results_students
        expect(ff(".outcome-student-cell-content")).to have_size 3

        select_section("All Sections")
        expect(section_filter).to have_value("All Sections")

        select_section(@other_section.name)
        expect(section_filter).to have_value(@other_section.name)

        expect(ff(".outcome-student-cell-content")).to have_size 1

        # verify that it remembers the section to show across page loads
        refresh_page
        expect(section_filter).to have_value(@other_section.name)
        expect(ff(".outcome-student-cell-content")).to have_size 1

        # now verify that you can set it back

        select_section("All Sections")

        expect(ff(".outcome-student-cell-content")).to have_size 3
      end

      it "handles multiple enrollments correctly" do
        @course.enroll_student(@student_1, section: @other_section, allow_multiple_enrollments: true)

        Gradebook.visit(@course)

        meta_cells = find_slick_cells(0, f(".grid-canvas"))
        expect(meta_cells[0]).to include_text @course.default_section.display_name
        expect(meta_cells[0]).to include_text @other_section.display_name

        switch_to_section(@course.default_section)
        meta_cells = find_slick_cells(0, f(".grid-canvas"))
        expect(meta_cells[0]).to include_text @student_name_1

        switch_to_section(@other_section)
        meta_cells = find_slick_cells(0, f(".grid-canvas"))
        expect(meta_cells[0]).to include_text @student_name_1
      end
    end
  end
end
