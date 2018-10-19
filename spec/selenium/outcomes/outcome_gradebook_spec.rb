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

require_relative '../helpers/gradebook_common'

describe "outcome gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
      @outcome1 = outcome_model(context: @course, title: 'outcome1')
      @outcome2 = outcome_model(context: @course, title: 'outcome2')
    end

    before(:each) do
      user_session(@teacher)
    end

    after(:each) do
      clear_local_storage
    end

    it "should not be visible by default" do
      get "/courses/#{@course.id}/gradebook"
      expect(f("#content")).not_to contain_css('.gradebook-navigation')
    end

    context "when enabled" do
      before :once do
        Account.default.set_feature_flag!('outcome_gradebook', 'on')
      end

      it "should be visible" do
        get "/courses/#{@course.id}/gradebook"
        expect(ff('.gradebook-navigation')).to have_size 1

        f('a[data-id=outcome]').click
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
        f('a[data-id=outcome]').click
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
        f('a[data-id=outcome]').click
        two_outcomes

        f('#no_results_outcomes').click
        no_outcomes

        f('#no_results_outcomes').click
        two_outcomes
      end

      it "filter out outcomes and students without results" do
        get "/courses/#{@course.id}/gradebook"
        f('a[data-id=outcome]').click
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
        f('a[data-id=outcome]').click
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
        f('a[data-id=outcome]').click
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
        f('a[data-id=outcome]').click
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
          f('a[data-id=outcome]').click
          wait_for_ajax_requests

          # mean
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.33'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '2.67'

          f('#no_results_outcomes').click
          wait_for_ajax_requests

          # mean
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.33'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '2.67'
        end

        it "displays course mean and median" do
          get "/courses/#{@course.id}/gradebook"
          f('a[data-id=outcome]').click
          wait_for_ajax_requests

          # mean
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.33'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '2.67'

          # median
          f('.al-trigger').click
          ff('.al-options .ui-menu-item').second.click
          wait_for_ajax_requests
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '3'

          # switch to first section
          f('.section-select-button').click
          section = @course.course_sections.first.id
          fj("label[for='section_option_#{section}']").click
          # not sure why two clicks are needed ...
          fj("label[for='section_option_#{section}']").click
          wait_for_ajax_requests

          # median
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.5'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '2.5'

          # switch to second section
          f('.section-select-button').click
          section = @course.course_sections.second.id
          fj("label[for='section_option_#{section}']").click
          wait_for_ajax_requests

          # refresh page
          refresh_page

          # should remain on second section, with mean
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 2
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2'
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').second.text).to eq '3'
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
          f('a[data-id=outcome]').click
          wait_for_ajax_requests

          # all but one result are non-scoring, so we display score
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score')).to have_size 1
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-score').first.text).to eq '2.33'
          # all results are non-scoring
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-description')).to have_size 1
          expect(ff('.outcome-gradebook-container .headerRow_1 .outcome-description').first.text).to eq 'Near Mastery'
        end
      end

      it "should allow showing only a certain section" do
        get "/courses/#{@course.id}/gradebook"
        f('a[data-id=outcome]').click
        expect(ff('.outcome-student-cell-content')).to have_size 3

        choose_section = ->(name) do
          fj('.section-select-button:visible').click
          fj(".section-select-menu:visible a:contains('#{name}')").click
          wait_for_ajaximations
        end

        choose_section.call "All Sections"
        expect(fj('.section-select-button:visible')).to include_text("All Sections")

        choose_section.call @other_section.name
        expect(fj('.section-select-button:visible')).to include_text(@other_section.name)
        expect(ff('.outcome-student-cell-content')).to have_size 1

        # verify that it remembers the section to show across page loads
        get "/courses/#{@course.id}/gradebook"
        expect(fj('.section-select-button:visible')).to include_text @other_section.name
        expect(ff('.outcome-student-cell-content')).to have_size 1

        # now verify that you can set it back

        fj('.section-select-button:visible').click
        expect(fj('.section-select-menu:visible')).to be_displayed
        f("label[for='section_option_']").click
        expect(fj('.section-select-button:visible')).to include_text "All Sections"

        expect(ff('.outcome-student-cell-content')).to have_size 3
      end

      it "should handle multiple enrollments correctly" do
        @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

        get "/courses/#{@course.id}/gradebook"

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
