#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../../helpers/speed_grader_common"
require_relative "../../helpers/gradebook_common"
require_relative "../../helpers/groups_common"
require_relative '../pages/speedgrader_page.rb'

describe "In speedgrader" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include SpeedGraderCommon
  include GroupsCommon

  context "as a teacher in course with unlimited sections " do
    before(:each) do
      @teacher_enrollment = course_with_teacher(course: @course, active_all: true)
      user_logged_in(user: @teacher)
      @assignment = @course.assignments.create(name: 'assignment with rubric', points_possible: 10)

      @section = @course.course_sections.create!
      student_in_course(active_all: true)
      @student1 = @student
      student_in_course(active_all: true)
      @student2 = @student
      @enrollment.course_section = @section
      @enrollment.save
    end

    it "switching between a section and all sections doesn’t cause errors", priority: "2" do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      Speedgrader.visit_section(Speedgrader.section_with_id(@section.id))
      expect(Speedgrader.student_x_of_x_label).to include_text("1/")

      Speedgrader.visit_section(Speedgrader.section_all)
      expect(Speedgrader.student_x_of_x_label).to include_text("/2")
    end
  end
end
