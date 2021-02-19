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

require_relative '../grades/pages/gradebook_page'
require_relative '../grades/setup/gradebook_setup'
require_relative '../helpers/gradebook_common'

describe "outcome gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
      @outcome1 = outcome_model(context: @course, title: 'outcome1')
      @outcome2 = outcome_model(context: @course, title: 'outcome2')
      show_sections_filter(@teacher)
    end

    before(:each) do
      user_session(@teacher)
    end

    after(:each) do
      clear_local_storage
    end

    def select_learning_mastery
      f('.assignment-gradebook-container .gradebook-menus button').click
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

    def median_values
      f('.al-trigger').click
      ff('.al-options .ui-menu-item').second.click
      wait_for_ajax_requests
      selected_values
    end

    def selected_values
      ff('.outcome-gradebook-container .headerRow_1 .outcome-score').map(&:text)
    end

    it "should not be visible by default" do
      Gradebook.visit(@course)
      f('.assignment-gradebook-container .gradebook-menus button').click
      expect(f("#content")).not_to contain_css('span[data-menu-item-id="learning-mastery"]')
    end

    context "when enabled" do
      before :once do
        Account.default.set_feature_flag!('outcome_gradebook', 'on')
      end

      it "should be visible" do
        Gradebook.visit(@course)
        Gradebook.gradebook_menu_element.click
        expect(f('span[data-menu-item-id="learning-mastery"]')).not_to be_nil
        f('span[data-menu-item-id="learning-mastery"]').click

        expect(f('.outcome-gradebook-container')).not_to be_nil
      end

      def three_students
        expect(ff('.outcome-student-cell-content')).to have_size 3
      end

      def no_students
        expect(f('#application')).not_to contain_css('.outcome-student-cell-content')
      end

      def two_outcomes
        expect(ff('.outcome-gradebook-container .headers_1 .slick-header-column')).to have_size 2
      end

      def no_outcomes
        expect(f('.outcome-gradebook-container .headers_1')).not_to contain_css('.slick-header-column')
      end

      it "filter out students without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        three_students

        f('#no_results_students').click
        wait_for_ajax_requests
        no_students

        f('#no_results_students').click
        wait_for_ajax_requests
        three_students
      end

      it "filter out outcomes without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        two_outcomes

        f('#no_results_outcomes').click
        no_outcomes

        f('#no_results_outcomes').click
        two_outcomes
      end

      it "filter out outcomes and students without results" do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        two_outcomes
        three_students

        f('#no_results_outcomes').click
        no_outcomes
        three_students

        f('#no_results_students').click
        wait_for_ajax_requests
        no_outcomes
        no_students

        f('#no_results_students').click
        wait_for_ajax_requests
        no_outcomes
        three_students

        f('#no_results_outcomes').click
        two_outcomes
        three_students

        f('#no_results_students').click
        wait_for_ajax_requests
        two_outcomes
        no_students
      end

      it 'outcomes without results filter preserved after page refresh' do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        wait_for_ajax_requests

        expect(f('#no_results_outcomes').selected?).to be false
        expect(f('#no_results_students').selected?).to be false

        f('#no_results_outcomes').click
        refresh_page

        expect(f('#no_results_outcomes').selected?).to be true
        expect(f('#no_results_students').selected?).to be false
      end

      it 'students without results filter preserved after page refresh' do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        wait_for_ajax_requests

        expect(f('#no_results_outcomes').selected?).to be false
        expect(f('#no_results_students').selected?).to be false

        f('#no_results_students').click
        refresh_page

        expect(f('#no_results_outcomes').selected?).to be false
        expect(f('#no_results_students').selected?).to be true
      end

      it 'outcomes and students without results filter preserved after page refresh' do
        get "/courses/#{@course.id}/gradebook"
        select_learning_mastery
        wait_for_ajax_requests

        expect(f('#no_results_outcomes').selected?).to be false
        expect(f('#no_results_students').selected?).to be false

        f('#no_results_outcomes').click
        f('#no_results_students').click
        refresh_page

        expect(f('#no_results_outcomes').selected?).to be true
        expect(f('#no_results_students').selected?).to be true
      end

      def result(user, alignment, score, opts = {})
        LearningOutcomeResult.create!(user: user, alignment: alignment, score: score, context: @course, **opts)
      end

      context 'with results' do
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

        it 'keeps course mean after outcomes without results filter enabled' do
          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # mean
          means = selected_values
          expect(means).to contain_exactly("2.33", "2.67")

          f('#no_results_outcomes').click
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

        context 'with inactive_concluded_lmgb_filters enabled' do
          before(:once) do
            Account.default.set_feature_flag!('inactive_concluded_lmgb_filters', 'on')
          end

          it 'correctly displays inactive enrollments when the filter option is selected' do
            StudentEnrollment.find_by(user_id: @student_1.id).deactivate

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_2.name, @student_3.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-inactive-enrollments"]').click
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students)
          end

          it 'correctly displays concluded enrollments when the filter option is selected' do
            StudentEnrollment.find_by(user_id: @student_1.id).conclude

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_2.name, @student_3.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-concluded-enrollments"]').click
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students)
          end

          it 'correctly displays unassessed students when the filter option is selected' do
            student_4 = User.create!(:name => 'Unassessed Student')
            student_4.register!
            @course.enroll_student(student_4)

            get "/courses/#{@course.id}/gradebook"
            select_learning_mastery
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students)

            f('button[data-component="lmgb-student-filter-trigger"]').click
            f('span[data-component="lmgb-student-filter-unassessed-students"]').click
            wait_for_ajax_requests

            active_students = [@student_1.name, @student_2.name, @student_3.name, student_4.name]
            student_names = ff('.outcome-student-cell-content').map {|cell| cell.text.split("\n")[0]}
            expect(student_names.sort).to eq(active_students.sort)
          end
        end

        context 'with learning mastery scales enabled' do
          before(:once) do
            @rating1 = OutcomeProficiencyRating.new(description: 'best', points: 10, mastery: true, color: '00ff00')
            @rating2 = OutcomeProficiencyRating.new(description: 'worst', points: 0, mastery: false, color: 'ff0000')
            @proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [@rating1, @rating2], context: Account.default)
            @calculation_method = OutcomeCalculationMethod.create!(context: Account.default, calculation_method: 'latest')
            @second_outcome_assignment = @course.assignments.create!(
              title: 'Outcome 1 Second Assignment',
              grading_type: 'points',
              points_possible: 10,
              submission_types: 'online_text_entry',
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

          Account.default.set_feature_flag!('account_level_mastery_scales', 'on')
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

          Account.default.set_feature_flag!('account_level_mastery_scales', 'on')

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
          @calculation_method.calculation_method = 'highest'
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

          Account.default.set_feature_flag!('account_level_mastery_scales', 'on')

          get "/courses/#{@course.id}/gradebook"
          select_learning_mastery
          wait_for_ajax_requests

          # mean
          averages = selected_values
          expect(averages).to contain_exactly("3.33", "7.78")

          # median
          medians = median_values
          expect(medians).to contain_exactly("3.33", "6.67")

          Account.default.set_feature_flag!('account_level_mastery_scales', 'off')

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

      context 'with non-scoring results' do
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
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 1
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.33'
          # all results are non-scoring
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-description')).to have_size 1
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-description').first.text).to eq 'Near Mastery'
        end
      end

      it "allows showing only a certain section" do
        Gradebook.visit(@course)
        f('.assignment-gradebook-container .gradebook-menus button').click
        f('span[data-menu-item-id="learning-mastery"]').click

        expect(ff('.outcome-student-cell-content')).to have_size 3

        select_section('All Sections')
        expect(section_filter).to have_value("All Sections")

        select_section(@other_section.name)
        expect(section_filter).to have_value(@other_section.name)

        expect(ff('.outcome-student-cell-content')).to have_size 1

        # verify that it remembers the section to show across page loads
        Gradebook.visit(@course)
        expect(section_filter).to have_value(@other_section.name)
        expect(ff('.outcome-student-cell-content')).to have_size 1

        # now verify that you can set it back

        select_section('All Sections')

        expect(ff('.outcome-student-cell-content')).to have_size 3
      end

      it "should handle multiple enrollments correctly" do
        @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

        Gradebook.visit(@course)

        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @course.default_section.display_name
        expect(meta_cells[0]).to include_text @other_section.display_name

        switch_to_section(@course.default_section)
        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @student_name_1

        switch_to_section(@other_section)
        meta_cells = find_slick_cells(0, f('.grid-canvas'))
        expect(meta_cells[0]).to include_text @student_name_1
      end
    end
  end
end
