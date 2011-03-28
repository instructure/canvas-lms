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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe CoursesController, :type => :integration do
  before do
    course_with_teacher_logged_in(:active_all => true)
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
  end

  it "should return course list" do
    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}]
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student'}]
      },
    ]
  end

  it "should only return teacher enrolled courses on ?enrollment_type=teacher" do
    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher' })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}]
      },
    ]
  end

  it "should return the list of students for the course" do
    first_user = @user
    new_user = User.create!(:name => 'Zombo')
    @course2.enroll_student(new_user).accept!

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    json.should == api_json_response([first_user, new_user],
        :only => %w(id name))
  end
end
