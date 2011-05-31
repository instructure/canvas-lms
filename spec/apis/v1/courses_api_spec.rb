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
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'my-course-sis')
  end

  it "should return course list" do
    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'sis_source_id' => nil,
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student'}],
        'sis_source_id' => 'my-course-sis',
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
        'enrollments' => [{'type' => 'teacher'}],
        'sis_source_id' => nil,
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

  it "should include user sis id if site admin" do
    Account.site_admin.add_user(@me)
    first_user = @user
    new_user = User.create!(:name => 'Zombo')
    @course2.enroll_student(new_user).accept!

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    json.should == api_json_response([first_user, new_user],
        :only => %w(id name), :methods => %w(sis_user_id))
  end

  it "should return the list of sections for the course" do
    user1 = @user
    user2 = User.create!(:name => 'Zombo')
    section1 = @course2.default_section
    section2 = @course2.course_sections.create!(:name => 'Section B')
    @course2.enroll_user(user2, 'StudentEnrollment', :section => section2).accept!

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
            { :controller => 'courses', :action => 'sections', :course_id => @course2.id.to_s, :format => 'json' }, { :include => ['students'] })
    json.size.should == 2
    json.find { |s| s['name'] == section1.name }['students'].should == api_json_response([user1], :only => %w(id name))
    json.find { |s| s['name'] == section2.name }['students'].should == api_json_response([user2], :only => %w(id name))
  end

  it "should allow specifying course sis id" do
    first_user = @user
    new_user = User.create!(:name => 'Zombo')
    @course2.update_attribute(:sis_source_id, 'my-course-sis')
    @course2.enroll_student(new_user).accept!

    json = api_call(:get, "/api/v1/courses/sis:my-course-sis/students.json",
            { :controller => 'courses', :action => 'students', :course_id => 'sis:my-course-sis', :format => 'json' })
    json.should == api_json_response([first_user, new_user],
        :only => %w(id name))
  end

  it "should return the needs_grading_count for all assignments" do
    @group = @course1.assignment_groups.create!({:name => "some group"})
    @assignment = @course1.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
    sub = @assignment.find_or_create_submission(@user)
    sub.workflow_state = 'submitted'
    update_with_protected_attributes!(sub, { :body => 'test!', 'submission_type' => 'online_text_entry' })

    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher&include[]=needs_grading_count",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher', :include=>["needs_grading_count"] })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'needs_grading_count' => 1,
        'sis_source_id' => nil,
      },
    ]
  end
end
