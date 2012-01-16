#
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
  describe "enrollment creation" do
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

  describe "enrollment listing" do
    before do
      course_with_student(:active_all => true, :user => user_with_pseudonym)
      @teacher = User.create(:name => 'Señor Chang')
      @teacher.pseudonyms.create(:unique_id => 'chang@example.com')
      @course.enroll_teacher(@teacher)
      User.all.each { |u| u.destroy unless u.pseudonym.present? }
      @path = "/api/v1/courses/#{@course.id}/enrollments"
      @params = { :controller => "enrollments_api", :action => "index", :course_id => @course.id.to_param, :format => "json" }
    end

    context "a student" do
      it "should list all members of a course" do
        json = api_call(:get, @path, @params)
        enrollments = %w{observer student ta teacher}.inject([]) do |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user, :order => 'users.sortable_name ASC')
        end
        json.should == enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
        }
      end

      it "should not include the users' sis and login ids" do
        json = api_call(:get, @path, @params)
        json.each do |res|
          %w{sis_user_id sis_login_id login_id}.each { |key| res['user'].should_not include(key) }
        end
      end
    end

    context "a teacher" do
      it "should include users' sis and login ids" do
        @user = @teacher

        json = api_call(:get, @path, @params)
        enrollments = %w{observer student ta teacher}.inject([]) do |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user)
        end
        json.should == enrollments.map do |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id,
              'sis_user_id' => e.user.pseudonym ? e.user.pseudonym.sis_user_id : nil,
              'sis_login_id' => e.user.pseudonym && e.user.sis_user_id ? e.user.pseudonym.unique_id : nil,
              'login_id' => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
            }
          }
        end
      end
    end

    context "a user without roster permissions" do
      it "should return 401 unauthorized" do
        @user = user_with_pseudonym(:name => 'Don Draper', :username => 'ddraper@sterling-cooper.com')
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/enrollments", @params.merge(:course_id => @course.id.to_param))
        response.code.should eql "401"
      end
    end

    describe "pagination" do
      it "should properly paginate" do
        json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(:page => 1.to_param, :per_page => 1.to_param))
        enrollments = %w{observer student ta teacher}.inject([]) { |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user)
        }.map do |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
        end
        link_header = response.headers['Link'].split(',')
        link_header[0].should match /page=2&per_page=1/ # next page
        link_header[1].should match /page=1&per_page=1/ # first page
        link_header[2].should match /page=2&per_page=1/ # last page
        json.should eql [enrollments[0]]

        json = api_call(:get, "#{@path}?page=2&per_page=1", @params.merge(:page => 2.to_param, :per_page => 1.to_param))
        link_header = response.headers['Link'].split(',')
        link_header[0].should match /page=1&per_page=1/ # prev page
        link_header[1].should match /page=1&per_page=1/ # first page
        link_header[2].should match /page=2&per_page=1/ # last page
        json.should eql [enrollments[1]]
      end
    end

    describe "filters" do
      it "should properly filter by a single enrollment type" do
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment", @params.merge(:type => %w{StudentEnrollment}))
        json.should eql @course.student_enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
        }
      end

      it "should properly filter by multiple enrollment types" do
        # set up some enrollments that shouldn't be returned by the api
        request_user = @user
        @new_user = user_with_pseudonym(:name => 'Zombo', :username => 'nobody2@example.com')
        @course.enroll_user(@new_user, 'TaEnrollment', 'active')
        @course.enroll_user(@new_user, 'ObserverEnrollment', 'active')
        @user = request_user
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment&type[]=TeacherEnrollment", @params.merge(:type => %w{StudentEnrollment TeacherEnrollment}))
        json.should == (@course.student_enrollments + @course.teacher_enrollments).map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
        }
      end
    end
  end
end

