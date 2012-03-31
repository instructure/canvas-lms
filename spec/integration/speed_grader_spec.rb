#
# Copyright (C) 2012 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "speed_grader" do
  it "should list the correct student count with multiple enrollments" do
    course_with_teacher_logged_in
    student_in_course
    add_section("other section")
    multiple_student_enrollment(@student, @course_section)
    @assignment = @course.assignments.create!(:title => "Test 1", :submission_types => "online_upload")

    get "courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    Nokogiri::HTML(response.body).css('#x_of_x_students').text.should match /of 1/
  end
end
