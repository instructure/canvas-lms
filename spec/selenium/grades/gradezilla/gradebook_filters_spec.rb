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
require_relative '../pages/gradezilla_page'
require_relative '../setup/gradebook_setup'

require_relative '../pages/gradezilla_cells_page'

describe "Filter" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GradebookSetup
  include GroupsCommon

  context "by Module" do
    before(:once) do
      course_with_teacher(active_all: true)
      @modules = Array.new(2) { |i| @course.context_modules.create! name: "Mod#{i}" }
      group = @course.assignment_groups.create! name: 'assignments'
      @assignments = Array.new(2) { |i| @course.assignments.create! assignment_group: group, title: "Assign#{i}"}
      2.times { |i| @modules[i].add_item type: 'assignment', id: @assignments[i].id }
    end

    before(:each) do
      show_modules_filter(@teacher)
      user_session(@teacher)
    end

    it "should allow showing only one module", test_id: 3253290, priority: "1" do
      Gradezilla.visit(@course)
      Gradezilla.module_dropdown_item_click(@modules[0].name)

      expect(Gradezilla.select_assignment_header_cell_element(@assignments[0].title)).to be_displayed
      expect(Gradezilla.content_selector).not_to contain_css(Gradezilla.assignment_header_cell_selector(@assignments[1].title))
    end
  end

  context "by Grading Period" do
    before(:once) do
      course_with_teacher(active_all: true)
      course_with_student(course: @course)
      create_grading_periods('Fall Term', Time.zone.now)
      associate_course_to_term("Fall Term")
    end

    before(:each) do
      user_session(@teacher)
      show_grading_periods_filter(@teacher)
    end

    it "should allow showing only one grading period", test_id: 3253292, priority: "1" do
      assign1 = @course.assignments.create! title: "Assign1", due_at: 1.week.from_now
      assign2 = @course.assignments.create! title: "Assign2", due_at: 1.week.ago

      Gradezilla.visit(@course)
      Gradezilla.select_grading_period(@gp_current.title)

      expect(Gradezilla.select_assignment_header_cell_element(assign1.title)).to be_displayed
      expect(Gradezilla.content_selector).not_to contain_css(Gradezilla.assignment_header_cell_selector(assign2.title))
    end
  end

  context "by Section" do
    before(:once) do
      gradebook_data_setup
      show_sections_filter(@teacher)
    end

    before(:each) { user_session(@teacher) }

    it "should handle multiple enrollments correctly" do
      @course.enroll_student(@student_1, section: @other_section, allow_multiple_enrollments: true)

      Gradezilla.visit(@course)

      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @course.default_section.display_name
      expect(meta_cells[0]).to include_text @other_section.display_name

      Gradezilla.select_section(@course.default_section)
      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @student_name_1

      Gradezilla.select_section(@other_section)
      meta_cells = find_slick_cells(0, f('.grid-canvas'))
      expect(meta_cells[0]).to include_text @student_name_1
    end

    it "should allow showing only a certain section", priority: "1", test_id: 3253291 do
      Gradezilla.visit(@course)
      Gradezilla.select_section("All Sections")

      # grade the first assignment
      Gradezilla::Cells.edit_grade(@student_1, @first_assignment, 0)
      Gradezilla::Cells.edit_grade(@student_2, @first_assignment, 1)

      Gradezilla.select_section(@other_section)
      expect(Gradezilla.section_dropdown).to include_text(@other_section.name)

      expect(Gradezilla::Cells.get_grade(@student_2, @first_assignment)).to eq '1'
    end
  end
end
