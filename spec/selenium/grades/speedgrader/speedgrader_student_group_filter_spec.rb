# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/speedgrader_page"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_grade_detail_tray_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../setup/gradebook_setup"
require_relative "../../assignments/page_objects/assignment_page"

describe "filter speed grader by student group" do
  include_context "in-process server selenium tests"
  include GradebookSetup

  before :once do
    # course with student groups
    course_with_teacher(
      course_name: "Filter Speedgrader Course",
      active_course: true,
      active_enrollment: true,
      name: "Dedicated Teacher1",
      active_user: true
    )
    @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
    @course.update!(filter_speed_grader_by_student_group: true)

    @assignment = @course.assignments.create!(
      title: "filtering assignment",
      submission_types: "online_text_entry",
      grading_type: "points",
      points_possible: 10
    )

    @students = create_users_in_course(@course, 4, return_type: :record, name_prefix: "Blue", section: @section1)

    @category = @course.group_categories.create!(name: "speedgrader filter groups")
    @category.create_groups(2)
    @category.groups.first.add_user(@students[0])
    @category.groups.first.add_user(@students[1])
    @category.groups.second.add_user(@students[2])
    @category.groups.second.add_user(@students[3])

    @group1_students = @students[0, 2]
    @group2_students = @students[2, 2]

    @course.update!(filter_speed_grader_by_student_group: true)
  end

  context "on assignments page" do
    before do
      user_session(@teacher)
      AssignmentPage.visit(@course.id, @assignment.id)
    end

    it "disables speedgrader when no group selected" do
      expect(AssignmentPage.speedgrader_link).to be_disabled
    end

    it "does not disable speedgrader link when a group is selected" do
      AssignmentPage.student_group_speedgrader_dropdown(@category.groups.first)
      expect(AssignmentPage.speedgrader_link).not_to be_disabled
    end
  end

  context "on gradebook details tray" do
    before do
      user_session(@teacher)
    end

    it "speedgrader link from tray has correct href" do
      show_student_groups_filter(@teacher)

      Gradebook.visit(@course)
      # select group from gradebook
      Gradebook.select_student_group(@category.groups.second)
      # verify link is disabled and message
      Gradebook::Cells.open_tray(@group2_students.second, @assignment)
      speedgrader_link_text = "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      expect(Gradebook::GradeDetailTray.speedgrader_link.attribute("href")).to include(speedgrader_link_text)
    end

    it "loads speedgrader when group selected" do
      skip("Unskip in EVAL-2501")
      # select group from gradebook setting
      @teacher.preferences[:gradebook_settings] = {
        @course.id => {
          filter_rows_by: {
            student_group_id: @category.groups.second.id
          }
        }
      }
      Speedgrader.visit(@course.id, @assignment.id)
      # verify
      Speedgrader.click_students_dropdown
      expect(Speedgrader.fetch_student_names).to contain_exactly(@group2_students)
    end

    it "disables speedgrader from tray" do
      Gradebook.visit(@course)
      # verify link is disabled and message
      Gradebook::Cells.open_tray(@group2_students.first, @assignment)
      expect(Gradebook::GradeDetailTray.group_message).to include_text("you must select a student group")
      expect(Gradebook::GradeDetailTray.speedgrader_link).to be_disabled
    end
  end
end
