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

require_relative "../../common"
require_relative "../../helpers/speed_grader_common"
require_relative '../../helpers/gradezilla_common'
require_relative "../pages/speedgrader_page"

describe "speed grader - grade display" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon
  include_context "late_policy_course_setup"
  include GradezillaCommon

  context "grade display" do
    POINTS = 10.0
    GRADE = 3.0

    before(:each) do
      course_with_teacher_logged_in
      create_and_enroll_students(2)
      @assignment = @course.assignments.create(name: 'assignment', points_possible: POINTS)
      @assignment.grade_student(@students[0], grade: GRADE, grader: @teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it "displays the score on the sidebar", priority: "1", test_id: 283993 do
      expect(Speedgrader.grade_value).to eq GRADE.to_int.to_s
    end

    it "displays total number of graded assignments to students", priority: "1", test_id: 283994 do
      expect(Speedgrader.fraction_graded).to include_text("1/2")
    end

    it "displays average submission grade for total assignment submissions", priority: "1", test_id: 283995 do
      average = (GRADE / POINTS * 100).to_int
      expect(Speedgrader.average_grade).to include_text("#{GRADE.to_int} / #{POINTS.to_int} (#{average}%)")
    end
  end

  context "late_policy_pills" do
    before(:once) do
      # create course with students, assignments, submissions and grades
      init_course_with_students(1)
      create_course_late_policy
      create_assignments
      make_submissions
      grade_assignments
    end

    before(:each) do
      user_session(@teacher)
    end

    it "shows late pill" do
      Speedgrader.visit(@course.id, @a1.id)

      expect(Speedgrader.submission_status_pill('late')).to be_displayed
    end

    it "shows late deduction and final grade" do
      Speedgrader.visit(@course.id, @a1.id)

      late_penalty_value = "-" + @course.students[0].submissions.find_by(assignment_id:@a1.id).points_deducted.to_s
      final_grade_value = @course.students[0].submissions.find_by(assignment_id:@a1.id).published_grade

      # the data from rails and data from ui are not in the same format
      expect(Speedgrader.late_points_deducted_text.to_f.to_s).to eq late_penalty_value
      expect(Speedgrader.final_late_policy_grade_text).to eq final_grade_value
    end

    it "shows missing pill" do
      Speedgrader.visit(@course.id, @a2.id)

      expect(Speedgrader.submission_status_pill('missing')).to be_displayed
    end
  end
end
