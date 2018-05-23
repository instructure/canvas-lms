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

require_relative '../../helpers/gradebook_common'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context "differentiated assignments" do
    before :once do
      gradebook_data_setup
      @da_assignment = assignment_model({
        :course => @course,
        :name => 'DA assignment',
        :points_possible => @assignment_1_points,
        :submission_types => 'online_text_entry',
        :assignment_group => @group,
        :only_visible_to_overrides => true
      })
      @override = create_section_override_for_assignment(@da_assignment, course_section: @other_section)
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should gray out cells" do
      get "/courses/#{@course.id}/gradebook"
      # student 3, assignment 4
      selector = '#gradebook_grid .container_1 .slick-row:nth-child(3) .b5'
      cell = f(selector)
      expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
      cell.click
      expect(cell).not_to contain_css('.grade')
      # student 2, assignment 4 (not grayed out)
      cell = f('#gradebook_grid .container_1 .slick-row:nth-child(2) .b5')
      expect(cell.find_element(:css, '.gradebook-cell')).not_to have_class('grayed-out')
    end

    it "should gray out cells after removing an override which removes visibility" do
      selector = '#gradebook_grid .container_1 .slick-row:nth-child(1) .b5'
      @da_assignment.grade_student(@student_1, grade: 42, grader: @teacher)
      @override.destroy
      get "/courses/#{@course.id}/gradebook"
      cell = f(selector)
      expect(cell.find_element(:css, '.gradebook-cell')).to have_class('grayed-out')
    end
  end
end
