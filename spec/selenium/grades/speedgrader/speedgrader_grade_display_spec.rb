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
require_relative "../page_objects/speedgrader_page"

describe "speed grader - grade display" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  POINTS = 10.0
  GRADE = 3.0

  before(:each) do
    course_with_teacher_logged_in
    create_and_enroll_students(2)
    @assignment = @course.assignments.create(name: 'assignment', points_possible: POINTS)
    @assignment.submit_homework(@students[0])
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
