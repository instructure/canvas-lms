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

require_relative '../helpers/gradezilla_common'
require_relative '../grades/pages/gradezilla_page'
require_relative '../grades/setup/gradebook_setup'

describe "outcome gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GradebookSetup

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
      show_sections_filter(@teacher)
    end

    before(:each) do
      user_session(@teacher)
    end

    after(:each) do
      clear_local_storage
    end

    it "should not be visible by default" do
      Gradezilla.visit(@course)
      expect(f("#content")).not_to contain_css('.gradebook-navigation')
    end

    context "when enabled" do
      before :once do
        Account.default.set_feature_flag!('outcome_gradebook', 'on')
      end

      it "is visible" do
        Gradezilla.visit(@course)
        f('.assignment-gradebook-container .gradebook-menus button').click
        f('span[data-menu-item-id="learning-mastery"]').click
        expect(f('.outcome-gradebook-container')).not_to be_nil
      end

      it "allows showing only a certain section" do
        Gradezilla.visit(@course)
        f('.assignment-gradebook-container .gradebook-menus button').click
        f('span[data-menu-item-id="learning-mastery"]').click

        expect(ff('.outcome-student-cell-content')).to have_size 3

        click_option('[data-component="SectionFilter"] select', 'All Sections')
        selected_section_name = ff('option', f('[data-component="SectionFilter"] select')).find(&:selected?)
        expect(selected_section_name).to include_text("All Sections")

        click_option('[data-component="SectionFilter"] select', @other_section.name)
        selected_section_name = ff('option', f('[data-component="SectionFilter"] select')).find(&:selected?)
        expect(selected_section_name).to include_text(@other_section.name)

        expect(ff('.outcome-student-cell-content')).to have_size 1

        # verify that it remembers the section to show across page loads
        Gradezilla.visit(@course)
        selected_section_name = ff('option', f('[data-component="SectionFilter"] select')).find(&:selected?)
        expect(selected_section_name).to include_text(@other_section.name)
        expect(ff('.outcome-student-cell-content')).to have_size 1

        # now verify that you can set it back

        click_option('[data-component="SectionFilter"] select', 'All Sections')

        expect(ff('.outcome-student-cell-content')).to have_size 3
      end

      it "should handle multiple enrollments correctly" do
        @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

        Gradezilla.visit(@course)

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
