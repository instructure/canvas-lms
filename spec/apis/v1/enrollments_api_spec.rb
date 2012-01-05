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

describe EnrollmentsApiController, :type => :integration do
  context "an admin user" do
    before do
      course_with_student(:active_all => true)
      Account.site_admin.add_user(@student)
      @unenrolled_user = user_with_pseudonym
      @section         = @course.course_sections.create
      @path            = "/api/v1/courses/#{@course.id}/enrollments"
      @path_options    = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
      @user            = @student
    end

    it "should create a new student enrollment" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :type                               => 'StudentEnrollment',
            :enrollment_state                     => 'active',
            :course_section_id                  => @section.id,
            :limit_privileges_to_course_section => true
          }
        }
      new_enrollment = Enrollment.find(json['id'])
      json.should == {
        'root_account_id'                    => @course.account.id,
        'id'                                 => new_enrollment.id,
        'user_id'                            => @unenrolled_user.id,
        'course_section_id'                  => @section.id,
        'limit_privileges_to_course_section' => true,
        'enrollment_state'                   => 'active',
        'course_id'                          => @course.id,
        'type'                               => 'StudentEnrollment'
      }
      new_enrollment.root_account_id.should eql @course.account.id
      new_enrollment.user_id.should eql @unenrolled_user.id
      new_enrollment.course_section_id.should eql @section.id
      new_enrollment.limit_privileges_to_course_section.should eql true
      new_enrollment.workflow_state.should eql 'active'
      new_enrollment.course_id.should eql @course.id
      new_enrollment.should be_an_instance_of StudentEnrollment
    end

    it "should create a new teacher enrollment" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id => @unenrolled_user.id,
            :type    => 'TeacherEnrollment',
            :enrollment_state => 'active',
            :course_section_id => @section.id,
            :limit_privileges_to_course_section => true
          }
        }
      Enrollment.find(json['id']).should be_an_instance_of TeacherEnrollment
    end

    it "should create a new ta enrollment" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id => @unenrolled_user.id,
            :type    => 'TaEnrollment',
            :enrollment_state => 'active',
            :course_section_id => @section.id,
            :limit_privileges_to_course_section => true
          }
        }
      Enrollment.find(json['id']).should be_an_instance_of TaEnrollment
    end

    it "should create a new observer enrollment" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id => @unenrolled_user.id,
            :type    => 'ObserverEnrollment',
            :enrollment_state => 'active',
            :course_section_id => @section.id,
            :limit_privileges_to_course_section => true
          }
        }
      Enrollment.find(json['id']).should be_an_instance_of ObserverEnrollment
    end

    it "should default new enrollments to the 'invited' state" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id => @unenrolled_user.id,
            :type => 'StudentEnrollment'
          }
        }

      Enrollment.find(json['id']).workflow_state.should eql 'invited'
    end

    it "should throw an error if no params are given" do
      raw_api_call :post, @path, @path_options, { :enrollment => {  } }
      response.code.should eql '403'
      JSON.parse(response.body).should == {
        'message' => 'No parameters given'
      }
    end

    it "should assume a StudentEnrollment if no type is given" do
      api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id } }
      JSON.parse(response.body)['type'].should eql 'StudentEnrollment'
    end

    it "should return an error if an invalid type is given" do
      raw_api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, :type => 'PandaEnrollment' } }
      JSON.parse(response.body)['message'].should eql 'Invalid type'
    end

    it "should return an error if no user_id is given" do
      raw_api_call :post, @path, @path_options, { :enrollment => { :type => 'StudentEnrollment' } }
      response.code.should eql '403'
      JSON.parse(response.body).should == {
        'message' => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment"
      }
    end
  end

  context "a teacher" do
    before do
      course_with_teacher(:active_all => true)
      @course_with_teacher    = @course
      @course_wo_teacher      = course
      @course                 = @course_with_teacher
      @unenrolled_user        = user_with_pseudonym
      @section                = @course.course_sections.create
      @path                   = "/api/v1/courses/#{@course.id}/enrollments"
      @path_options           = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
      @user                   = @teacher
    end

    it "should create enrollments for its own class" do
      json = api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :type                               => 'StudentEnrollment',
            :enrollment_state                   => 'active',
            :course_section_id                  => @section.id,
            :limit_privileges_to_course_section => true
          }
        }
      new_enrollment = Enrollment.find(json['id'])
      json.should == {
        'root_account_id'                    => @course.account.id,
        'id'                                 => new_enrollment.id,
        'user_id'                            => @unenrolled_user.id,
        'course_section_id'                  => @section.id,
        'limit_privileges_to_course_section' => true,
        'enrollment_state'                   => 'active',
        'course_id'                          => @course.id,
        'type'                               => 'StudentEnrollment'
      }
      new_enrollment.root_account_id.should eql @course.account.id
      new_enrollment.user_id.should eql @unenrolled_user.id
      new_enrollment.course_section_id.should eql @section.id
      new_enrollment.limit_privileges_to_course_section.should eql true
      new_enrollment.workflow_state.should eql 'active'
      new_enrollment.course_id.should eql @course.id
      new_enrollment.should be_an_instance_of StudentEnrollment
    end

    it "should not create an enrollment for another class" do
      raw_api_call :post, "/api/v1/courses/#{@course_wo_teacher.id}/enrollments", @path_options.merge(:course_id => @course_wo_teacher.id.to_s),
        {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :type                               => 'StudentEnrollment'
          }
        }
      response.code.should eql '401'
    end
  end

  context "a student" do
    before do
      course_with_student(:active_all => true)
      @unenrolled_user        = user_with_pseudonym
      @path                   = "/api/v1/courses/#{@course.id}/enrollments"
      @path_options           = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
      @user                   = @student
    end

    it "should return 401 Unauthorized" do
      raw_api_call :post, @path, @path_options,
        {
          :enrollment => {
            :user_id => @unenrolled_user,
            :type    => 'StudentEnrollment'
          }
        }
      response.code.should eql '401'
    end
  end
end
