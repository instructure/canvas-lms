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
require_relative '../../helpers/assignment_overrides'
require_relative '../pages/gradezilla_page'

describe "Gradezilla - arrange by due date" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradezillaCommon

  before(:once) do
    gradebook_data_setup
    @assignment = @course.assignments.first
  end

  before(:each) do
    user_session(@teacher)
    Gradezilla.visit(@course)
  end

  it "validates arrange columns by due date option", priority: "1", test_id: 3253270 do
    expected_text = "–"

    Gradezilla.open_view_menu_and_arrange_by_menu
    Gradezilla.view_arrange_by_submenu_item('Due Date - Oldest to Newest').click
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))

    expect(first_row_cells[0]).to include_text expected_text

    driver.action.send_keys(:escape).perform
    Gradezilla.open_view_menu_and_arrange_by_menu

    expect(Gradezilla.popover_menu_item_checked?('Due Date - Oldest to Newest')).to eq 'true'

    # Setting should stick after reload
    Gradezilla.visit(@course)
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text expected_text

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text expected_text
    expect(first_row_cells[1]).to include_text @assignment_1_points
    expect(first_row_cells[2]).to include_text @assignment_2_points

    Gradezilla.open_view_menu_and_arrange_by_menu

    expect(Gradezilla.popover_menu_item_checked?('Due Date - Oldest to Newest')).to eq 'true'
  end

  it "should put assignments with no due date last when sorting by due date and VDD", priority: "2", test_id: 251038 do
    assignment2 = @course.assignments.where(title: 'second assignment').first
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 1 section
    @section_a = @course.course_sections.create!(name: 'Section A')
    # give second assignment a default due date and an override
    assignment2.update!(due_at: 3.days.from_now)
    create_assignment_override(assignment2, @section_a, 2)

    Gradezilla.open_view_menu_and_arrange_by_menu
    Gradezilla.view_arrange_by_submenu_item('Due Date - Oldest to Newest').click

    # since due date changes in assignments don't reflect in column sorting without a refresh
    Gradezilla.visit(@course)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(1)')).to include_text(assignment3.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(2)')).to include_text(assignment2.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(3)')).to include_text(@assignment.title)
  end

  it "should arrange columns by due date when multiple due dates are present", priority: "2", test_id: 378823 do
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 2 sections
    @section_a = @course.course_sections.create!(name: 'Section A')
    @section_b = @course.course_sections.create!(name: 'Section B')
    # give each assignment a default due date
    @assignment.update!(due_at: 3.days.from_now)
    assignment3.update!(due_at: 2.days.from_now)
    # creating overrides in each section
    create_assignment_override(@assignment, @section_a, 5)
    create_assignment_override(assignment3, @section_b, 4)

    Gradezilla.open_view_menu_and_arrange_by_menu
    Gradezilla.view_arrange_by_submenu_item('Due Date - Oldest to Newest').click

    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(1)')).to include_text(assignment3.title)
    expect(f('#gradebook_grid .container_1 .slick-header-column:nth-child(2)')).to include_text(@assignment.title)
  end
end
