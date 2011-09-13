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
  USER_API_FIELDS = %w(id name sortable_name)
  before do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @user.pseudonym.update_attribute(:sis_user_id, 'user1')
    @user.pseudonym.update_attribute(:sis_source_id, 'login-id')
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
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student'}],
        'sis_course_id' => 'TEST-SIS-ONE.2011',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course2.uuid}.ics" },
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
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
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
        :only => USER_API_FIELDS)
  end

  it "should not include user sis id or login id for non-admins" do
    first_user = @user
    new_user = User.create!(:name => 'Zombo')
    @course2.enroll_student(new_user).accept!

    @user = @me
    json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    %w{sis_user_id sis_login_id unique_id}.each do |attribute|    
      json.map { |u| u[attribute] }.should == [nil, nil]
    end
  end

  it "should include user sis id and login id if account admin" do
    @course2.account.add_user(@me)
    first_user = @user
    new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
    @course2.enroll_student(new_user).accept!
    new_user.pseudonym.update_attribute(:sis_user_id, 'user2')
    new_user.pseudonym.update_attribute(:sis_source_id, 'login-2')

    @user = @me
    json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
    json.map { |u| u['sis_login_id'] }.sort.should == ['login-id', 'login-2'].sort
    json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
  end
  
  it "should include user sis id and login id if can manage_students in the course" do
    @course1.grants_right?(@me, :manage_students).should be_true
    first_student = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
    @course1.enroll_student(first_student).accept!
    first_student.pseudonym.update_attribute(:sis_user_id, 'user2')
    first_student.pseudonym.update_attribute(:sis_source_id, 'login-2')
    second_student = user_with_pseudonym(:name => 'second student', :username => 'nobody3@example.com')
    @course1.enroll_student(second_student).accept!
    second_student.pseudonym.update_attribute(:sis_user_id, 'user3')
    second_student.pseudonym.update_attribute(:sis_source_id, 'login-3')
    
    @user = @me
    json = api_call(:get, "/api/v1/courses/#{@course1.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course1.to_param, :format => 'json' })
    json.map { |u| u['sis_user_id'] }.sort.should == ['user2', 'user3'].sort
    json.map { |u| u['sis_login_id'] }.sort.should == ['login-2', 'login-3'].sort
    json.map { |u| u['login_id'] }.sort.should == ['nobody2@example.com', 'nobody3@example.com'].sort
  end

  it "should include user sis id and login id if site admin" do
    Account.site_admin.add_user(@me)
    first_user = @user
    new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
    @course2.enroll_student(new_user).accept!
    new_user.pseudonym.update_attribute(:sis_user_id, 'user2')
    new_user.pseudonym.update_attribute(:sis_source_id, 'login-2')

    @user = @me
    json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
            { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
    json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
    json.map { |u| u['sis_login_id'] }.sort.should == ['login-id', 'login-2'].sort
    json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
  end

  it "should return the list of sections for the course" do
    user1 = @user
    user2 = User.create!(:name => 'Zombo')
    section1 = @course2.default_section
    section2 = @course2.course_sections.create!(:name => 'Section B')
    section2.update_attribute :sis_source_id, 'sis-section'
    @course2.enroll_user(user2, 'StudentEnrollment', :section => section2).accept!

    json = api_call(:get, "/api/v1/courses/#{@course2.id}/sections.json",
            { :controller => 'courses', :action => 'sections', :course_id => @course2.id.to_s, :format => 'json' }, { :include => ['students'] })
    json.size.should == 2
    json.find { |s| s['name'] == section2.name }['sis_section_id'].should == 'sis-section'
    json.find { |s| s['name'] == section1.name }['students'].should == api_json_response([user1], :only => USER_API_FIELDS)
    json.find { |s| s['name'] == section2.name }['students'].should == api_json_response([user2], :only => USER_API_FIELDS)
  end

  it "should allow specifying course sis id" do
    first_user = @user
    new_user = User.create!(:name => 'Zombo')
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @course2.enroll_student(new_user).accept!

    json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011/students.json",
            { :controller => 'courses', :action => 'students', :course_id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
    json.should == api_json_response([first_user, new_user],
        :only => USER_API_FIELDS)

    json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
            { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
    json['id'].should == @course2.id
    json['sis_course_id'].should == 'TEST-SIS-ONE.2011'
  end

  it "should allow sis id in hex packed format" do
    sis_id = 'This.Sis/Id\\Has Nasty?Chars'
    # sis_id.unpack('H*').first
    packed_sis_id = '546869732e5369732f49645c486173204e617374793f4368617273'
    @course1.update_attribute(:sis_source_id, sis_id)
    json = api_call(:get, "/api/v1/courses/hex:sis_course_id:#{packed_sis_id}.json",
            { :controller => 'courses', :action => 'show', :id => "hex:sis_course_id:#{packed_sis_id}", :format => 'json' })
    json['id'].should == @course1.id
    json['sis_course_id'].should == sis_id
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
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
      },
    ]
  end
  
  it "should return the course syllabus" do
    @course1.syllabus_body = "Syllabi are boring"
    @course1.save
    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher&include[]=syllabus_body",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher', :include=>["syllabus_body"] })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'syllabus_body' => @course1.syllabus_body,
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
      },
    ]
  end

  it "should get individual course data" do
    json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
            { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
    json['id'].should == @course1.id
  end
end
