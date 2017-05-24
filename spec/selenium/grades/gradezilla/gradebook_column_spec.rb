#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla - assignment column headers" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradezillaCommon

  before(:once) do
    gradebook_data_setup
    @assignment = @course.assignments.first
    @header_selector = %([id$="assignment_#{@assignment.id}"])
  end

  before(:each) do
    user_session(@teacher)
  end

  it "should validate row sorting works when first column is clicked", priority: "1", test_id: 220023 do
    pending("to be added back in with CNVS-31611")
    Gradezilla.visit(@course)
    first_column = f('.slick-column-name')
    first_column.click
    meta_cells = find_slick_cells(0, f('#gradebook_grid  .container_0'))
    grade_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    #filter validation
    expect(meta_cells[0]).to include_text @student_name_3 + "\n" + @course.name
    expect(grade_cells[0]).to include_text @assignment_2_points
    expect(grade_cells[4].find_element(:css, '.percentage')).to include_text @student_3_total_ignoring_ungraded
  end

  it "should have a tooltip with the assignment name", priority: "1", test_id: 220025 do
    Gradezilla.visit(@course)
    expect(f(@header_selector)["title"]).to eq @assignment.title
  end

  it "should handle a ton of assignments without wrapping the slick-header", priority: "1", test_id: 220026 do
    create_assignments([@course.id], 100, title: 'a really long assignment name, o look how long I am this is so cool')
    Gradezilla.visit(@course)
    # being 38px high means it did not wrap
    expect(f("#gradebook_grid .slick-header-columns").size.height).to eq 38
  end

  it "should load custom column ordering", priority: "1", test_id: 220031 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!
    Gradezilla.visit(@course)
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text '-'
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text @assignment_1_points

    # none of the predefined short orders should be selected.
    Gradezilla.open_view_menu_and_arrange_by_menu
    arrangement_menu_options_aria_checked =
      Gradezilla.popover_menu_items.map { |i| i.attribute('aria-checked') }

    expect(arrangement_menu_options_aria_checked).to all eq('false')
  end

  it "should put new assignments at the end when columns have custom order", priority: "1", test_id: 220032 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!
    @fourth_assignment = assignment_model({
      :course => @course,
      :name => "new assignment",
      :due_at => nil,
      :points_possible => 150,
      :assignment_group => nil,
      })
    @fourth_assignment.grade_student(@student_1, grade: 150, grader: @teacher)

    Gradezilla.visit(@course)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text '-'
    expect(first_row_cells[1]).to include_text @assignment_2_points
    expect(first_row_cells[2]).to include_text @assignment_1_points
    expect(first_row_cells[3]).to include_text '150'
  end

  it "should maintain order of remaining assignments if an assignment is destroyed", priority: "1", test_id: 220033 do
    @user.preferences[:gradebook_column_order] = {}
    @user.preferences[:gradebook_column_order][@course.id] = {
      sortType: 'custom',
      customOrder: ["#{@third_assignment.id}", "#{@second_assignment.id}", "#{@first_assignment.id}"]
    }
    @user.save!

    @first_assignment.destroy

    Gradezilla.visit(@course)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    expect(first_row_cells[0]).to include_text '-'
    expect(first_row_cells[1]).to include_text @assignment_2_points
  end

  it "should show letter grade in total column", priority: "1", test_id: 220035 do
    row1_selector = '#gradebook_grid .container_1 .slick-row:nth-child(1) .total-cell .letter-grade-points'
    row2_selector = '#gradebook_grid .container_1 .slick-row:nth-child(2) .total-cell .letter-grade-points'

    Gradezilla.visit(@course)
    expect(f(row1_selector)).to include_text("A")
    Gradezilla.enter_grade('50', 0,1)
    edit_grade('#gradebook_grid .slick-row:nth-child(2) .l2', '50')
    expect(f(row2_selector)).to include_text("A")
  end
end
