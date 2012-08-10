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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

class TestCourseApi
  include Api::V1::Course
  def feeds_calendar_url(feed_code); "feed_calendar_url(#{feed_code.inspect})"; end
  def course_url(course, opts = {}); return "course_url(Course.find(#{course.id}), :host => #{HostUrl.context_host(@course1)})"; end
end

describe Api::V1::Course do

  before do
    @test_api = TestCourseApi.new
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @user.pseudonym.update_attribute(:sis_user_id, 'user1')
  end

  it 'should support optionally providing the url' do
    @test_api.course_json(@course1, @me, {}, ['html_url'], []).should encompass({
      "html_url" => "course_url(Course.find(#{@course1.id}), :host => #{HostUrl.context_host(@course1)})"
    })
    @test_api.course_json(@course1, @me, {}, [], []).has_key?("html_url").should be_false
  end

  it 'should only include needs_grading_count if requested' do
    @teacher_enrollment = @course1.teacher_enrollments.first
    @test_api.course_json(@course1, @me, {}, [], [@teacher_enrollment]).has_key?("needs_grading_count").should be_false
  end

  it 'should honor needs_grading_count for teachers' do
    @teacher_enrollment = @course1.teacher_enrollments.first
    @test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [@teacher_enrollment]).has_key?("needs_grading_count").should be_true
  end

  it 'should not honor needs_grading_count for designers' do
    @designer_enrollment = @course1.enroll_designer(@me)
    @designer_enrollment.accept!
    @test_api.course_json(@course1, @me, {}, ['needs_grading_count'], [@designer_enrollment]).has_key?("needs_grading_count").should be_false
  end
end

describe CoursesController, :type => :integration do
  USER_API_FIELDS = %w(id name sortable_name short_name)

  before do
    Course.any_instance.stubs(:start_at).returns nil
    Course.any_instance.stubs(:end_at).returns nil
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:name => 'UWP'))
    @me = @user
    @course1 = @course
    course_with_student(:user => @user, :active_all => true)
    @course2 = @course
    @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
    @user.pseudonym.update_attribute(:sis_user_id, 'user1')
  end

  it "should return course list" do
    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'account_id' => @course2.account_id,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student'}],
        'sis_course_id' => 'TEST-SIS-ONE.2011',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course2.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
    ]
  end

  describe "course creation" do
    context "an account admin" do
      before do
        Course.any_instance.unstub(:start_at, :end_at)
        @account = Account.default
        account_admin_user
        @resource_path = "/api/v1/accounts/#{@account.id}/courses"
        @resource_params = { :controller => 'courses', :action => 'create', :format => 'json', :account_id => @account.id.to_s }
      end

      it "should create a new course" do
        post_params = {
          'account_id' => @account.id,
          'offer'      => true,
          'course'     => {
            'name'                                 => 'Test Course',
            'course_code'                          => 'Test Course',
            'start_at'                             => '2011-01-01T00:00:00-0700',
            'end_at'                               => '2011-05-01T00:00:00-0700',
            'publish_grades_immediately'           => true,
            'is_public'                            => true,
            'allow_student_assignment_edits'       => true,
            'allow_wiki_comments'                  => true,
            'allow_student_forum_attachments'      => true,
            'open_enrollment'                      => true,
            'self_enrollment'                      => true,
            'restrict_enrollments_to_course_dates' => true,
            'license'                              => 'Creative Commons',
            'sis_course_id'                        => '12345',
            'public_description'                   => 'Nature is lethal but it doesn\'t hold a candle to man.'
          }
        }
        course_response = post_params['course'].merge({
          'account_id' => @account.id,
          'root_account_id' => @account.id,
          'start_at' => '2011-01-01T07:00:00Z',
          'end_at' => '2011-05-01T07:00:00Z',
          'workflow_state' => 'available',
        })
        json = api_call(:post, @resource_path, @resource_params, post_params)
        new_course = Course.find(json['id'])
        [:name, :course_code, :start_at, :end_at, :publish_grades_immediately,
        :is_public, :allow_student_assignment_edits, :allow_wiki_comments,
        :open_enrollment, :self_enrollment, :license, :sis_course_id,
        :allow_student_forum_attachments, :public_description,
        :restrict_enrollments_to_course_dates].each do |attr|
          [:start_at, :end_at].include?(attr) ?
            new_course.send(attr).should == Time.parse(post_params['course'][attr.to_s]) :
            new_course.send(attr).should == post_params['course'][attr.to_s]
        end
        new_course.account_id.should eql @account.id
        new_course.workflow_state.should eql 'available'
        course_response.merge!(
          'id' => new_course.id,
          'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{new_course.uuid}.ics" }
        )
        json.should eql course_response
      end

      it "should offer a course if passed the 'offer' parameter" do
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :offer => true, :course => { :name => 'Test Course' } }
        )
        new_course = Course.find(json['id'])
        new_course.should be_available
      end

      it "should allow setting sis_course_id without offering the course" do
        json = api_call(:post, @resource_path,
          @resource_params,
          { :account_id => @account.id, :course => { :name => 'Test Course', :sis_course_id => '9999' } }
        )
        new_course = Course.find(json['id'])
        new_course.sis_source_id.should == '9999'
      end
    end

    context "a user without permissions" do
      it "should return 401 Unauthorized if a user lacks permissions" do
        course_with_student(:active_all => true)
        account = Account.default
        raw_api_call(:post, "/api/v1/accounts/#{account.id}/courses",
          { :controller => 'courses', :action => 'create', :format => 'json', :account_id => account.id.to_s },
          {
            :account_id => account.id,
            :course => {
              :name => 'Test Course'
            }
          }
        )
        response.status.should eql '401 Unauthorized'
      end
    end
  end

  describe "course deletion" do
    before do
      account_admin_user
      @path = "/api/v1/courses/#{@course.id}"
      @params = { :controller => 'courses', :action => 'destroy', :format => 'json', :id => @course.id.to_s }
    end
    context "an authorized user" do
      it "should be able to delete a course" do
        json = api_call(:delete, @path, @params, { :event => 'delete' })
        json.should == { 'delete' => true }
        @course.reload
        @course.workflow_state.should eql 'deleted'
      end

      it "should be able to complete a course" do
        json = api_call(:delete, @path, @params, { :event => 'conclude' })
        json.should == { 'conclude' => true }
        @course.reload
        @course.workflow_state.should eql 'completed'
      end

      it "should return 400 if params[:event] is missing" do
        json = raw_api_call(:delete, @path, @params)
        response.code.should eql '400'
        JSON.parse(response.body).should == {
          'message' => 'Only "delete" and "conclude" events are allowed.'
        }

      end

      it "should return 400 if an unknown event type is used" do
        raw_api_call(:delete, @path, @params, { :event => 'rm -rf like a boss' })
        response.code.should eql '400'
        JSON.parse(response.body).should == {
          'message' => 'Only "delete" and "conclude" events are allowed.'
        }
      end
    end
    context "an unauthorized user" do
      it "should return 401" do
        @user = @student
        raw_api_call(:delete, @path, @params, { :event => 'conclude' })
        response.code.should eql '401'
      end
    end
  end

  it "should include scores in course list if requested" do
    @course2.grading_standard_enabled = true
    @course2.save
    expected_current_score = 80
    expected_final_score = 70
    expected_final_grade = @course2.score_to_grade(expected_final_score)
    @course2.all_student_enrollments.update_all(
      :computed_current_score => expected_current_score,
      :computed_final_score => expected_final_score)

    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' },
            { :include => ['total_scores'] })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'account_id' => @course2.account_id,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student',
                           'computed_current_score' => expected_current_score,
                           'computed_final_score' => expected_final_score,
                           'computed_final_grade' => expected_final_grade}],
        'sis_course_id' => 'TEST-SIS-ONE.2011',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course2.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
    ]
  end

  it "should not include scores in course list, even if requested, if final grades are hidden" do
    @course2.grading_standard_enabled = true
    @course2.settings[:hide_final_grade] = true
    @course2.save
    @course2.all_student_enrollments.update_all(:computed_current_score => 80, :computed_final_score => 70)

    json = api_call(:get, "/api/v1/courses.json",
            { :controller => 'courses', :action => 'index', :format => 'json' },
            { :include => ['total_scores'] })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
      {
        'id' => @course2.id,
        'name' => @course2.name,
        'account_id' => @course2.account_id,
        'course_code' => @course2.course_code,
        'enrollments' => [{'type' => 'student'}],
        'sis_course_id' => 'TEST-SIS-ONE.2011',
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course2.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      }
    ]
  end

  it "should only return teacher enrolled courses on ?enrollment_type=teacher" do
    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher' })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      }
    ]
  end

  describe "/students" do
    it "should return the list of students for the course" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      json.sort_by{|x| x["id"]}.should == api_json_response([first_user, new_user],
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}
    end

    it "should not include user sis id or login id for non-admins" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

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

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
      json.map { |u| u['sis_login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
      json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should include user sis id and login id if can manage_students in the course" do
      @course1.grants_right?(@me, :manage_students).should be_true
      first_student = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course1.enroll_student(first_student).accept!
      first_student.pseudonym.update_attribute(:sis_user_id, 'user2')
      second_student = user_with_pseudonym(:name => 'second student', :username => 'nobody3@example.com')
      @course1.enroll_student(second_student).accept!
      second_student.pseudonym.update_attribute(:sis_user_id, 'user3')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course1.to_param, :format => 'json' })
      json.map { |u| u['sis_user_id'] }.sort.should == ['user2', 'user3'].sort
      json.map { |u| u['sis_login_id'] }.sort.should == ['nobody2@example.com', 'nobody3@example.com'].sort
      json.map { |u| u['login_id'] }.sort.should == ['nobody2@example.com', 'nobody3@example.com'].sort
    end

    it "should include user sis id and login id if site admin" do
      Account.site_admin.add_user(@me)
      first_user = @user
      new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course2.enroll_student(new_user).accept!
      new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => @course2.id.to_s, :format => 'json' })
      json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
      json.map { |u| u['sis_login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
      json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should allow specifying course sis id" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
      @course2.enroll_student(new_user).accept!
      ro = RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011/students.json",
                      { :controller => 'courses', :action => 'students', :course_id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
      json.sort_by{|x| x["id"]}.should == api_json_response([first_user, new_user],
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}

      ro.destroy
      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
                      { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' })
      json['id'].should == @course2.id
      json['sis_course_id'].should == 'TEST-SIS-ONE.2011'
    end
  end

  describe "/users" do
    before(:each) do
      section1 = @course1.default_section
      section2 = @course1.course_sections.create!(:name => 'Section B')
      @ta = user(:name => 'TA')
      @student1 = user(:name => 'S1')
      @student2 = user(:name => 'S2')
      @ta_enroll1 = @course1.enroll_user(@ta, 'TaEnrollment', :section => section1)
      @ta_enroll2 = @course1.enroll_user(@ta, 'TaEnrollment', :section => section2, :allow_multiple_enrollments => true)
      @student1_enroll = @course1.enroll_user(@student1, 'StudentEnrollment', :section => section1)
      @student2_enroll = @course1.enroll_user(@student2, 'StudentEnrollment', :section => section2)
    end

    it "returns a list of users" do
      # when
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' })
      # expect
      json.sort_by{|x| x["id"]}.should == api_json_response(@course1.users.uniq,
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}
    end

    it "returns a list of users with emails" do
      # when
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                      :include => ['email'])
      # expect
      json.sort_by{|x| x["id"]}.should == api_json_response(@course1.users.uniq,
                                                            :only => USER_API_FIELDS, :methods => ['email']
                                                            ).sort_by{|x| x["id"]}
    end

    it "returns a list of users and enrollments with enrollments option" do
      # when
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                      :include => ['enrollments'])
      # helper
      check_json = lambda { |user, *enrollments|
        j = json.find { |x| x['id'] == user.id }
        j.delete('enrollments').map { |e| e['id'] }.sort.
          should == enrollments.map(&:id)
        j.should == api_json_response(user, :only => USER_API_FIELDS)
      }
      # expect
      check_json.call(@ta, @ta_enroll1, @ta_enroll2)
      check_json.call(@student1, @student1_enroll)
      check_json.call(@student2, @student2_enroll)
    end

    it "doesn't return enrollments from another course" do
      # given
      other_enroll = @course2.enroll_user(@student1, 'StudentEnrollment')
      # when
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                      :include => ['enrollments'])
      # expect
      enroll_ids = json.find { |x| x['id'] == @student1.id }['enrollments'].map { |e| e['id'] }.sort
      enroll_ids.should == [@student1_enroll.id]
    end

    it "optionally filters users by enrollment_type" do
      # when
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.id.to_s, :format => 'json' },
                      :enrollment_type => 'student')
      # expect
      json.map {|x| x["id"]}.sort.should == api_json_response([@student1, @student2],
                                                              :only => USER_API_FIELDS).map {|x| x["id"]}.sort
    end

    it "should not include user sis id or login id for non-admins" do
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.enroll_student(new_user).accept!
      RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                      :enrollment_type => 'student')
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

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                      :enrollment_type => 'student')
      json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
      json.map { |u| u['sis_login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
      json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should include user sis id and login id if can manage_students in the course" do
      @course1.grants_right?(@me, :manage_students).should be_true
      first_student = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course1.enroll_student(first_student).accept!
      first_student.pseudonym.update_attribute(:sis_user_id, 'user2')
      second_student = user_with_pseudonym(:name => 'second student', :username => 'nobody3@example.com')
      @course1.enroll_student(second_student).accept!
      second_student.pseudonym.update_attribute(:sis_user_id, 'user3')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course1.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course1.to_param, :format => 'json' },
                      :enrollment_type => 'student')
      json.map { |u| u['sis_user_id'] }.compact.sort.should == ['user2', 'user3'].sort
      json.map { |u| u['sis_login_id'] }.compact.sort.should == ['nobody2@example.com', 'nobody3@example.com'].sort
      json.map { |u| u['login_id'] }.compact.sort.should == ['nobody2@example.com', 'nobody3@example.com'].sort
    end

    it "should include user sis id and login id if site admin" do
      Account.site_admin.add_user(@me)
      first_user = @user
      new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
      @course2.enroll_student(new_user).accept!
      new_user.pseudonym.update_attribute(:sis_user_id, 'user2')

      @user = @me
      json = api_call(:get, "/api/v1/courses/#{@course2.id}/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => @course2.id.to_s, :format => 'json' },
                      :enrollment_type => 'student')
      json.map { |u| u['sis_user_id'] }.sort.should == ['user1', 'user2'].sort
      json.map { |u| u['sis_login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
      json.map { |u| u['login_id'] }.sort.should == ["nobody@example.com", "nobody2@example.com"].sort
    end

    it "should allow specifying course sis id" do
      @user = @me
      first_user = @user
      new_user = User.create!(:name => 'Zombo')
      @course2.update_attribute(:sis_source_id, 'TEST-SIS-ONE.2011')
      @course2.enroll_student(new_user).accept!
      ro = RoleOverride.create!(:context => Account.default, :permission => 'read_sis', :enrollment_type => 'TeacherEnrollment', :enabled => false)

      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011/users.json",
                      { :controller => 'courses', :action => 'users', :course_id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' },
                      :enrollment_type => 'student')
      json.sort_by{|x| x["id"]}.should == api_json_response([first_user, new_user],
                                                            :only => USER_API_FIELDS).sort_by{|x| x["id"]}

      ro.destroy
      json = api_call(:get, "/api/v1/courses/sis_course_id:TEST-SIS-ONE.2011.json",
                      { :controller => 'courses', :action => 'show', :id => 'sis_course_id:TEST-SIS-ONE.2011', :format => 'json' },
                      :enrollment_type => 'student')
      json['id'].should == @course2.id
      json['sis_course_id'].should == 'TEST-SIS-ONE.2011'
    end
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

  it "should not find courses in other root accounts" do
    acct = account_model(:name => 'root')
    acct.add_user(@user)
    course(:account => acct)
    @course.update_attribute('sis_source_id', 'OTHER-SIS')
    raw_api_call(:get, "/api/v1/courses/sis_course_id:OTHER-SIS",
                 :controller => "courses", :action => "show", :id => "sis_course_id:OTHER-SIS", :format => "json")
    response.status.should == "404 Not Found"
  end

  it "should return the needs_grading_count for all assignments" do
    @group = @course1.assignment_groups.create!({:name => "some group"})
    @assignment = @course1.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
    student_in_course(:course => @course1, :active_all => true)
    @assignment.submit_homework(@user, :body => 'test!', 'submission_type' => 'online_text_entry')
    @user = @me

    json = api_call(:get, "/api/v1/courses.json?enrollment_type=teacher&include[]=needs_grading_count",
            { :controller => 'courses', :action => 'index', :format => 'json', :enrollment_type => 'teacher', :include=>["needs_grading_count"] })
    json.should == [
      {
        'id' => @course1.id,
        'name' => @course1.name,
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'needs_grading_count' => 1,
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
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
        'account_id' => @course1.account_id,
        'course_code' => @course1.course_code,
        'enrollments' => [{'type' => 'teacher'}],
        'syllabus_body' => @course1.syllabus_body,
        'sis_course_id' => nil,
        'calendar' => { 'ics' => "http://www.example.com/feeds/calendars/course_#{@course1.uuid}.ics" },
        'start_at' => nil,
        'end_at' => nil
      },
    ]
  end

  it "should get individual course data" do
    json = api_call(:get, "/api/v1/courses/#{@course1.id}.json",
            { :controller => 'courses', :action => 'show', :id => @course1.to_param, :format => 'json' })
    json['id'].should == @course1.id
  end

  context "course files" do
    it_should_behave_like "file uploads api with folders"
    it_should_behave_like "file uploads api with quotas"
    
    before :each do
      @context = @course
    end

    def preflight(preflight_params)
      @user = @teacher
      api_call(:post, "/api/v1/courses/#{@course.id}/files",
        { :controller => "courses", :action => "create_file", :format => "json", :course_id => @course.to_param, },
        preflight_params)
    end

    def has_query_exemption?
      false
    end
      
    def context
      @course
    end

    it "should require the correct permission to upload" do
      @user = student_in_course(:course => @course).user
      api_call(:post, "/api/v1/courses/#{@course.id}/files",
        { :controller => "courses", :action => "create_file", :format => "json", :course_id => @course.to_param, },
        { :name => 'failboat.txt' }, {}, :expected_status => 401)
    end
  end
end

def each_copy_option
  [[:assignments, :assignments], [:external_tools, :context_external_tools], [:files, :attachments], 
   [:topics, :discussion_topics], [:calendar_events, :calendar_events], [:quizzes, :quizzes], 
   [:modules, :context_modules], [:outcomes, :learning_outcomes]].each{|o| yield o}
end

describe ContentImportsController, :type => :integration do
  before(:each) do
    course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
    @copy_from = @course
    @copy_from.sis_source_id = 'from_course'
    
    # create one of everything that can be copied
    group = @course.assignment_groups.create!(:name => 'group1')
    @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => group)
    @copy_from.discussion_topics.create!(:title => "Topic 1", :message => "<p>watup?</p>")
    @copy_from.syllabus_body = "haha"
    @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => 'hi')
    @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com')
    Attachment.create!(:filename => 'wut.txt', :display_name => "huh?", :uploaded_data => StringIO.new('uh huh.'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
    @copy_from.calendar_events.create!(:title => 'event', :description => 'hi', :start_at => 1.day.from_now)
    @copy_from.context_modules.create!(:name => "a module")
    @copy_from.quizzes.create!(:title => 'quiz')
    LearningOutcomeGroup.default_for(@copy_from).add_item(@copy_from.learning_outcomes.create!(:short_description => 'oi', :context => @copy_from))
    @copy_from.save
    
    course_with_teacher(:active_all => true, :name => 'whatever', :user => @user)
    @copy_to = @course
    @copy_to.sis_source_id = 'to_course'
    @copy_to.save
  end
  
  def run_copy(to_id=nil, from_id=nil, options={})
    to_id ||= @copy_to.to_param
    from_id ||= @copy_from.to_param
    data = api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id}.merge(options))

    cm = ContentMigration.last(:order => :id)
    data.should == {
      'id' => cm.id,
      'progress' => nil,
      'status_url' => "http://www.example.com/api/v1/courses/#{@copy_to.to_param}/course_copy/#{cm.id}",
      'created_at' => cm.created_at.as_json,
      'workflow_state' => 'created',
    }

    status_url = data['status_url']
    dj = Delayed::Job.last

    api_call(:get, status_url, { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
    (JSON.parse(response.body)).tap do |res|
      res['workflow_state'].should == 'created'
      res['progress'].should be_nil
    end
    
    dj.invoke_job
    cm.reload
    cm.migration_settings[:warnings].should == nil
    cm.content_export.error_messages.should == []

    api_call(:get, status_url, { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => data['id'].to_param, :format => 'json' })
    (JSON.parse(response.body)).tap do |res|
      res['workflow_state'].should == 'completed'
      res['progress'].should == 100
    end
  end
  
  def run_unauthorized(to_id, from_id)
    status = raw_api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id})
    status.should == 401
  end
  
  def run_not_found(to_id, from_id)
    status = raw_api_call(:post, "/api/v1/courses/#{to_id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => to_id, :format => 'json' },
    {:source_course => from_id})
    response.status.should == "404 Not Found"
  end
  
  def run_only_copy(option)
    run_copy(nil, nil, {:only => [option]})
  end
  
  def run_except_copy(option)
    run_copy(nil, nil, {:except => [option]})
  end
  
  def check_counts(expected_count, skip = nil)
    each_copy_option do |option, association|
      next if skip && option == skip
      next if !Qti.qti_enabled? && association == :quizzes
      @copy_to.send(association).count.should == expected_count
    end
  end
  
  it "should copy a course with canvas id" do
    run_copy
    check_counts 1
  end
  
  it "should copy a course using sis ids" do
    run_copy('sis_course_id:to_course', 'sis_course_id:from_course')
    check_counts 1
  end
  
  it "should not allow copying into an unauthorized course" do
    course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
    run_unauthorized(@copy_to.to_param, @course.to_param)
  end
  
  it "should not allow copying from an unauthorized course" do
    course_with_teacher_logged_in(:active_all => true, :name => 'origin story')
    run_unauthorized(@course.to_param, @copy_from.to_param)
  end
  
  it "should return 404 for a source course that isn't found" do
    run_not_found(@copy_to.to_param, "0")
  end
  
  it "should return 404 for a destination course that isn't found" do
    run_not_found("0", @copy_from.to_param)
  end
  
  it "should return 404 for an import that isn't found" do
    raw_api_call(:get, "/api/v1/courses/#{@copy_to.id}/course_copy/444", 
                 { :controller => 'content_imports', :action => 'copy_course_status', :course_id => @copy_to.to_param, :id => '444', :format => 'json' })
    response.status.should == "404 Not Found"
  end
  
  it "shouldn't allow both only and except options" do
    raw_api_call(:post, "/api/v1/courses/#{@copy_to.id}/course_copy",
            { :controller => 'content_imports', :action => 'copy_course_content', :course_id => @copy_to.to_param, :format => 'json' },
    {:source_course => @copy_from.to_param, :only => [:topics], :except => [:assignments]})
    response.status.to_i.should == 400
    json = JSON.parse(response.body)
    json['errors'].should == 'You can not use "only" and "except" options at the same time.'
  end
  
  it "should only copy course settings" do
    run_only_copy(:course_settings)
    check_counts 0
    @copy_to.reload
    @copy_to.syllabus_body.should == "<p>haha</p>"
  end
  it "should only copy wiki pages" do
    run_only_copy(:wiki_pages)
    check_counts 0
    @copy_to.wiki.wiki_pages.count.should == 1
  end
  each_copy_option do |option, association|
    it "should only copy #{option}" do
      pending if !Qti.qti_enabled? && association == :quizzes
      run_only_copy(option)
      @copy_to.send(association).count.should == 1
      check_counts(0, option)
    end
  end
  
  it "should skip copy course settings" do
    run_except_copy(:course_settings)
    check_counts 1
    @copy_to.reload
    @copy_to.syllabus_body.should == nil
  end
  it "should skip copy wiki pages" do
    run_except_copy(:wiki_pages)
    check_counts 1
    @copy_to.wiki.wiki_pages.count.should == 0
  end
  each_copy_option do |option, association|
    it "should skip copy #{option}" do
      run_except_copy(option)
      @copy_to.send(association).count.should == 0
      check_counts(1, option)
    end
  end
end
