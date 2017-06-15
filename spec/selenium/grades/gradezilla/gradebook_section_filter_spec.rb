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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/groups_common'
require_relative '../page_objects/gradezilla_page'
require_relative '../setup/gradebook_setup'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GradebookSetup
  include GroupsCommon

  before(:once) do
    gradebook_data_setup
    show_sections_filter(@teacher)
  end

  before(:each) { user_session(@teacher) }

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

  it "should allow showing only a certain section", priority: "1", test_id: 3253291 do
    Gradezilla.visit(@course)
    # grade the first assignment
    edit_grade(".slick-row.student_#{@student_1.id} .slick-cell.assignment_#{@first_assignment.id}", 0)
    edit_grade(".slick-row.student_#{@student_2.id} .slick-cell.assignment_#{@first_assignment.id}", 1)

    switch_to_section(@other_section)
    expect(ff('option', Gradezilla.section_dropdown).find(&:selected?)).to include_text @other_section.name

    expect(f(".slick-row.student_#{@student_2.id} .slick-cell.assignment_#{@first_assignment.id}")).to include_text '1'

    # verify that it remembers the section to show across page loads
    Gradezilla.visit(@course)
    expect(ff('option', Gradezilla.section_dropdown).find(&:selected?)).to include_text @other_section.name
    expect(f(".slick-row.student_#{@student_2.id} .slick-cell.assignment_#{@first_assignment.id}")).to include_text '1'

    # now verify that you can set it back

    switch_to_section('All Sections')
    expect(ff('option', Gradezilla.section_dropdown).find(&:selected?)).to include_text 'All Sections'

    # validate all grades (i.e. submissions) were loaded
    expect(f(".slick-row.student_#{@student_1.id} .slick-cell.assignment_#{@first_assignment.id}")).to include_text '0'
    expect(f(".slick-row.student_#{@student_2.id} .slick-cell.assignment_#{@first_assignment.id}")).to include_text '1'
  end
end
