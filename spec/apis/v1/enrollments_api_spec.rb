# coding: utf-8
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
        site_admin_user(:active_all => true)
        course(:active_course => true)
        @unenrolled_user = user_with_pseudonym
        @section         = @course.course_sections.create!
        @path            = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options    = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
        @user            = @admin
      end

      it "should create a new student enrollment" do
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
          'limit_privileges_to_course_section' => false,
          'enrollment_state'                   => 'active',
          'course_id'                          => @course.id,
          'type'                               => 'StudentEnrollment',
          'html_url'                           => course_user_url(@course, @unenrolled_user),
          'grades'                             => {
            'html_url' => course_student_grades_url(@course, @unenrolled_user),
            'final_score' => nil,
            'current_score' => nil
          },
          'associated_user_id'                 => nil,
          'updated_at'                         => new_enrollment.updated_at.xmlschema
        }
        new_enrollment.root_account_id.should eql @course.account.id
        new_enrollment.user_id.should eql @unenrolled_user.id
        new_enrollment.course_section_id.should eql @section.id
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

      it "should default new enrollments to the 'invited' state in the default section" do
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type => 'StudentEnrollment'
            }
          }

        e = Enrollment.find(json['id'])
        e.workflow_state.should eql 'invited'
        e.course_section.should eql @course.default_section
      end

      it "should default new enrollments to the 'creation_pending' state for unpublished courses" do
        @course.update_attribute(:workflow_state, 'claimed')
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type => 'StudentEnrollment'
            }
          }

        e = Enrollment.find(json['id'])
        e.workflow_state.should eql 'creation_pending'
        e.course_section.should eql @course.default_section
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

      it "should enroll to the right section using the section-specific URL" do
        @path         = "/api/v1/sections/#{@section.id}/enrollments"
        @path_options = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :section_id => @section.id.to_s }
        json = api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, } }

        Enrollment.find(json['id']).course_section.should eql @section
      end

      it "should optionally not send notifications" do
        StudentEnrollment.any_instance.expects(:save_without_broadcasting).at_least_once

        api_call(:post, @path, @path_options, {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :enrollment_state                   => 'active',
            :notify                             => false }})
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
          'limit_privileges_to_course_section' => false,
          'enrollment_state'                   => 'active',
          'course_id'                          => @course.id,
          'type'                               => 'StudentEnrollment',
          'html_url'                           => course_user_url(@course, @unenrolled_user),
          'grades'                             => {
            'html_url' => course_student_grades_url(@course, @unenrolled_user),
            'final_score' => nil,
            'current_score' => nil
          },
          'associated_user_id'                 => nil,
          'updated_at'                         => new_enrollment.updated_at.xmlschema
        }
        new_enrollment.root_account_id.should eql @course.account.id
        new_enrollment.user_id.should eql @unenrolled_user.id
        new_enrollment.course_section_id.should eql @section.id
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
      @user_path = "/api/v1/users/#{@user.id}/enrollments"
      @params = { :controller => "enrollments_api", :action => "index", :course_id => @course.id.to_param, :format => "json" }
      @user_params = { :controller => "enrollments_api", :action => "index", :user_id => @user.id.to_param, :format => "json" }
      @section = @course.course_sections.create!
    end

    context "an account admin" do
      before do
        @user = user_with_pseudonym(:username => 'admin@example.com')
        Account.default.add_user(@user)
      end

      it "should list all of a user's enrollments in an account" do
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.current_enrollments.scoped(:include => :user, :order => 'users.sortable_name ASC')
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
              'id' => e.user.id,
              'login_id' => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
            },
            'html_url' => course_user_url(e.course_id, e.user_id),
            'grades' => {
              'html_url' => course_student_grades_url(e.course_id, e.user_id),
              'final_score' => nil,
              'current_score' => nil
            },
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema
          }
        }
      end

      it "should return enrollments for unpublished courses" do
        course
        @course.claim
        enrollment = course.enroll_student(@student)
        enrollment.update_attribute(:workflow_state, 'active')

        # without a state[] filter
        json = api_call(:get, @user_path, @user_params)
        json.map { |e| e['id'] }.should include enrollment.id

        # with a state[] filter
        json = api_call(:get, "#{@user_path}?state[]=active",
                        @user_params.merge(:state => %w{active}))
        json.map { |e| e['id'] }.should include enrollment.id
      end

      it "should not return enrollments from other accounts" do
        # enroll the user in a course in another account
        account = Account.create!(:name => 'Account Two')
        course = course(:account => account, :course_name => 'Account Two Course', :active_course => true)
        course.enroll_user(@student).accept!

        json = api_call(:get, @user_path, @user_params)
        json.length.should eql 1
      end

      it "should list section enrollments properly" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!

        @path = "/api/v1/sections/#{@section.id}/enrollments"
        @params = { :controller => "enrollments_api", :action => "index", :section_id => @section.id.to_param, :format => "json" }
        json = api_call(:get, @path, @params)

        json.length.should eql 1
        json.all?{ |r| r["course_section_id"] == @section.id }.should be_true
      end
    end

    context "a student" do
      it "should list all members of a course" do
        current_user = @user
        enrollment = @course.enroll_user(user)
        enrollment.accept!

        @user = current_user
        json = api_call(:get, @path, @params)
        enrollments = %w{observer student ta teacher}.inject([]) do |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user, :order => 'users.sortable_name ASC')
        end
        json.should == enrollments.map { |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
          # should display the user's own grades
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil
          } if e.student? && e.user_id == @user.id
          # should not display grades for other users.
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user)
          } if e.student? && e.user_id != @user.id

          h
        }
      end

      it "should filter by enrollment workflow_state" do
        @teacher.enrollments.first.update_attribute(:workflow_state, 'completed')
        json = api_call(:get, "#{@path}?state[]=completed", @params.merge(:state => %w{completed}))
        json.count.should be > 0
        json.each { |e| e['enrollment_state'].should eql 'completed' }
      end

      it "should list its own enrollments" do
        json = api_call(:get, @user_path, @user_params)
        enrollments = @user.current_enrollments.scoped(:include => :user, :order => 'users.sortable_name ASC')
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
            },
            'html_url' => course_user_url(e.course_id, e.user_id),
            'grades' => {
              'html_url' => course_student_grades_url(e.course_id, e.user_id),
              'final_score' => nil,
              'current_score' => nil
            },
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema
          }
        }
      end

      it "should not display grades when hide_final_grade is true for the course" do
        @course.settings[:hide_final_grade] = true
        @course.save

        json = api_call(:get, @user_path, @user_params)
        json[0]['grades'].keys.should eql %w{html_url}
      end

      it "should not show enrollments for courses that aren't published" do
        # Setup test with an unpublished course and an active enrollment in
        # that course.
        course
        @course.claim
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'active')

        # Request w/o a state[] filter.
        json = api_call(:get, @user_path, @user_params)
        json.map { |e| e['id'] }.should_not include enrollment.id

        # Request w/ a state[] filter.
        json = api_call(:get, "#{@user_path}?state[]=active&type[]=StudentEnrollment",
                        @user_params.merge(:state => %w{active}, :type => %w{StudentEnrollment}))
        json.map { |e| e['id'] }.should_not include enrollment.id
      end

      it "should not include the users' sis and login ids" do
        json = api_call(:get, @path, @params)
        json.each do |res|
          %w{sis_user_id sis_login_id login_id}.each { |key| res['user'].should_not include(key) }
        end
      end
    end

    context "a teacher" do
      before do
        @user = @teacher
      end

      it "should include users' sis and login ids" do
        json = api_call(:get, @path, @params)
        enrollments = %w{observer student ta teacher}.inject([]) do |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user)
        end
        json.should == enrollments.map do |e|
          user_json = {
                        'name' => e.user.name,
                        'sortable_name' => e.user.sortable_name,
                        'short_name' => e.user.short_name,
                        'id' => e.user.id,
                        'login_id' => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
                      }
          user_json.merge!({
              'sis_user_id' => e.user.pseudonym.sis_user_id,
              'sis_login_id' => e.user.pseudonym.unique_id,
            }) if e.user.pseudonym && e.user.pseudonym.sis_user_id
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => user_json,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil
          } if e.student?
          h
        end
      end
    end

    context "a user without permissions" do
      before do
        @user = user_with_pseudonym(:name => 'Don Draper', :username => 'ddraper@sterling-cooper.com')
      end

      it "should return 401 unauthorized for a course listing" do
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/enrollments", @params.merge(:course_id => @course.id.to_param))
        response.code.should eql "401"
      end

      it "should return 401 unauthorized for a user listing" do
        raw_api_call(:get, @user_path, @user_params)
        response.code.should eql "401"
      end
    end

    describe "pagination" do
      it "should properly paginate" do
        json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(:page => 1.to_param, :per_page => 1.to_param))
        enrollments = %w{observer student ta teacher}.inject([]) { |res, type|
          res = res + @course.send("#{type}_enrollments").scoped(:include => :user)
        }.map do |e|
          h = {
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
            },
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil
          } if e.student?
          h
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

    describe "enrollment deletion and conclusion" do
      before do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
        @enrollment = @student.enrollments.first

        @teacher = User.create!(:name => 'Test Teacher')
        @teacher.pseudonyms.create!(:unique_id => 'test+teacher@example.com')
        @course.enroll_teacher(@teacher)
        @user = @teacher

        @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}"
        @params = { :controller => 'enrollments_api', :action => 'destroy', :course_id => @course.id.to_param,
          :id => @enrollment.id.to_param, :format => 'json' }

        time = Time.now
        Time.stubs(:now).returns(time)
      end

      context "an authorized user" do
        it "should be able to conclude an enrollment" do
          json = api_call(:delete, "#{@path}?task=conclude", @params.merge(:task => 'conclude'))
          @enrollment.reload
          json.should == {
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => 'completed',
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
              'html_url' => course_student_grades_url(@course, @student),
              'final_score' => nil,
              'current_score' => nil
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema
          }
        end

        it "should be able to delete an enrollment" do
          json = api_call(:delete, "#{@path}?task=delete", @params.merge(:task => 'delete'))
          @enrollment.reload
          json.should == {
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => 'deleted',
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
              'html_url' => course_student_grades_url(@course, @student),
              'final_score' => nil,
              'current_score' => nil
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema
          }
        end

        it "should not be able to unenroll itself if it can't re-enroll itself" do
          enrollment = @teacher.enrollments.first

          @path.sub!(@enrollment.id.to_s, enrollment.id.to_s)
          @params.merge!(:id => enrollment.id.to_param, :task => 'delete')

          raw_api_call(:delete, "#{@path}?task=delete", @params)

          response.code.should eql '401'
          JSON.parse(response.body).should == {
            'message' => 'You are not authorized to perform that action.',
            'status'  => 'unauthorized'
          }
        end
      end

      context "an unauthorized user" do
        it "should return 401" do
          @user = @student
          raw_api_call(:delete, @path, @params)
          response.code.should eql '401'

          raw_api_call(:delete, "#{@path}?type=delete", @params.merge(:type => 'delete'))
          response.code.should eql '401'
        end
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
            'html_url' => course_user_url(@course, e.user),
            'grades' => {
              'html_url' => course_student_grades_url(@course, e.user),
              'final_score' => nil,
              'current_score' => nil
            },
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
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
        @course.enroll_user(@new_user, 'TaEnrollment', :enrollment_state => 'active')
        @course.enroll_user(@new_user, 'ObserverEnrollment', :enrollment_state => 'active')
        @user = request_user
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment&type[]=TeacherEnrollment", @params.merge(:type => %w{StudentEnrollment TeacherEnrollment}))
        json.should == (@course.student_enrollments + @course.teacher_enrollments).map { |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'user' => {
              'name' => e.user.name,
              'sortable_name' => e.user.sortable_name,
              'short_name' => e.user.short_name,
              'id' => e.user.id
            }
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil
          } if e.student?
          h
        }
      end

      it "should return an empty array when no user enrollments match a filter" do
        site_admin_user(:active_all => true)

        json = api_call(:get, "#{@user_path}?type[]=TeacherEnrollment",
          @user_params.merge(:type => %w{TeacherEnrollment}))

        json.should be_empty
      end
    end
  end
end

