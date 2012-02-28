#
# Copyright (C) 2011 Instructure, Inc.
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

describe "assignments" do
  def multiple_section_submissions
    course_with_student(:active_all => true); @student1 = @student
    @s2enrollment = student_in_course(:active_all => true); @student2 = @user

    @section = @course.course_sections.create!
    @s2enrollment.course_section = @section; @s2enrollment.save!

    @assignment = @course.assignments.create!(:title => "Test 1", :submission_types => "online_upload")

    @submission1 = @assignment.submit_homework(@student1, :submission_type => "online_text_entry", :body => "hi")
    @submission2 = @assignment.submit_homework(@student2, :submission_type => "online_text_entry", :body => "there")
  end

  it "should correctly list ungraded and total submissions for teacher" do
    multiple_section_submissions

    course_with_teacher_logged_in(:course => @course, :active_all => true)
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    response.should be_success
    Nokogiri::HTML(response.body).at_css('.graded_count').text.should match(/0 out of 2/)
  end

  it "should correctly list ungraded and total submissions for ta" do
    multiple_section_submissions

    @taenrollment = course_with_ta(:course => @course, :active_all => true)
    @taenrollment.limit_privileges_to_course_section = true
    @taenrollment.save!
    user_session(@ta)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    response.should be_success
    Nokogiri::HTML(response.body).at_css('.graded_count').text.should match(/0 out of 1/)
  end
end
