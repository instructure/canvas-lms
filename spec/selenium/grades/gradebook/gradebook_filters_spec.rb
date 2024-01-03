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
require_relative "../../helpers/groups_common"
require_relative "../pages/gradebook_page"
require_relative "../setup/gradebook_setup"

require_relative "../pages/gradebook_cells_page"

describe "Filter" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup
  include GroupsCommon

  context "by Module" do
    before(:once) do
      course_with_teacher(active_all: true)
      @modules = Array.new(2) { |i| @course.context_modules.create! name: "Mod#{i}" }
      group = @course.assignment_groups.create! name: "assignments"
      @assignments = Array.new(2) { |i| @course.assignments.create! assignment_group: group, title: "Assign#{i}" }
      2.times { |i| @modules[i].add_item type: "assignment", id: @assignments[i].id }
    end

    before do
      show_modules_filter(@teacher)
      user_session(@teacher)
    end

    it "allows showing only one module", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.module_dropdown_item_click(@modules[0].name)

      expect(Gradebook.select_assignment_header_cell_element(@assignments[0].title)).to be_displayed
      expect(Gradebook.content_selector).not_to contain_css(Gradebook.assignment_header_cell_selector(@assignments[1].title))
    end
  end

  context "by Grading Period" do
    before(:once) do
      course_with_teacher(active_all: true)
      course_with_student(course: @course)
      create_grading_periods("Fall Term", Time.zone.now)
      associate_course_to_term("Fall Term")
    end

    before do
      user_session(@teacher)
      show_grading_periods_filter(@teacher)
    end

    it "allows showing only one grading period", priority: "1" do
      assign1 = @course.assignments.create! title: "Assign1", due_at: 1.week.from_now
      assign2 = @course.assignments.create! title: "Assign2", due_at: 1.week.ago

      Gradebook.visit(@course)
      Gradebook.select_grading_period(@gp_current.title)

      expect(Gradebook.select_assignment_header_cell_element(assign1.title)).to be_displayed
      expect(Gradebook.content_selector).not_to contain_css(Gradebook.assignment_header_cell_selector(assign2.title))
    end
  end

  context "by Section" do
    before(:once) do
      gradebook_data_setup
      show_sections_filter(@teacher)
    end

    before { user_session(@teacher) }

    it "handles multiple enrollments correctly" do
      @course.enroll_student(@student_1, section: @other_section, allow_multiple_enrollments: true)

      Gradebook.visit(@course)

      meta_cells = find_slick_cells(0, f(".grid-canvas"))
      expect(meta_cells[0]).to include_text @course.default_section.display_name
      expect(meta_cells[0]).to include_text @other_section.display_name

      Gradebook.select_section(@course.default_section)
      meta_cells = find_slick_cells(0, f(".grid-canvas"))
      expect(meta_cells[0]).to include_text @student_name_1

      Gradebook.select_section(@other_section)
      meta_cells = find_slick_cells(0, f(".grid-canvas"))
      expect(meta_cells[0]).to include_text @student_name_1
    end
  end

  context "by Student Group" do
    before(:once) do
      gradebook_data_setup
      show_student_groups_filter(@teacher)

      @category = @course.group_categories.create!(name: "a group category")
      @category.create_groups(2)

      @category.groups.first.add_user(@student_1)
      @category.groups.second.add_user(@student_2)
    end

    before { user_session(@teacher) }

    it "allows showing only a specific student group", priority: "1" do
      Gradebook.visit(@course)
      Gradebook.select_student_group("All Student Groups")

      Gradebook::Cells.edit_grade(@student_1, @first_assignment, 0)
      Gradebook::Cells.edit_grade(@student_2, @first_assignment, 1)

      group2 = @category.groups.second
      Gradebook.select_student_group(group2)
      expect(Gradebook.student_group_dropdown).to have_value(group2.name)

      expect(Gradebook::Cells.get_grade(@student_2, @first_assignment)).to eq "1"
    end
  end
end
