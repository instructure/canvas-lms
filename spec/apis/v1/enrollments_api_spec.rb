# coding: utf-8
#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe EnrollmentsApiController, type: :request do
  describe "enrollment creation" do
    context "an admin user" do
      before :once do
        account_admin_user(:active_all => true)
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
              :limit_privileges_to_course_section => true,
              :start_at                           => nil,
              :end_at                             => nil
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
          'sis_import_id'                       => nil,
          'type'                               => 'StudentEnrollment',
          'role'                               => 'StudentEnrollment',
          'html_url'                           => course_user_url(@course, @unenrolled_user),
          'grades'                             => {
            'html_url' => course_student_grades_url(@course, @unenrolled_user),
            'final_score' => nil,
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          },
          'associated_user_id'                 => nil,
          'updated_at'                         => new_enrollment.updated_at.xmlschema,
          'created_at'                         => new_enrollment.created_at.xmlschema,
          'last_activity_at'                   => nil,
          'total_activity_time'                => 0,
          'sis_course_id'                      => @course.sis_source_id,
          'course_integration_id'              => @course.integration_id,
          'sis_section_id'                     => @section.sis_source_id,
          'section_integration_id'             => @section.integration_id,
          'start_at'                           => nil,
          'end_at'                             => nil
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

      it "should enroll a designer" do
        json = api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, :type => 'DesignerEnrollment' } }
        json['type'].should eql 'DesignerEnrollment'
        @unenrolled_user.enrollments.find(json['id']).should be_an_instance_of(DesignerEnrollment)
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

      it "should not notify by default" do
        StudentEnrollment.any_instance.expects(:save_without_broadcasting).at_least_once

        api_call(:post, @path, @path_options, {
            :enrollment => {
                :user_id                            => @unenrolled_user.id,
                :enrollment_state                   => 'active'}})
      end

      it "should optionally send notifications" do
        StudentEnrollment.any_instance.expects(:save).at_least_once

        api_call(:post, @path, @path_options, {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :enrollment_state                   => 'active',
            :notify                             => true }})
      end

      it "should not allow enrollments to be added to a hard-concluded course" do
        @course.complete
        raw_api_call :post, @path, @path_options, {
          :enrollment => {
            :user_id                            => @unenrolled_user.id,
            :type                               => 'StudentEnrollment',
            :enrollment_state                   => 'active',
            :course_section_id                  => @section.id,
            :limit_privileges_to_course_section => true
          }
        }

        JSON.parse(response.body)['message'].should eql 'Can\'t add an enrollment to a concluded course.'
      end

      it "should not allow enrollments to be added to a soft-concluded course" do
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        raw_api_call :post, @path, @path_options, {
            :enrollment => {
                :user_id                            => @unenrolled_user.id,
                :type                               => 'StudentEnrollment',
                :enrollment_state                   => 'active',
                :course_section_id                  => @section.id,
                :limit_privileges_to_course_section => true
            }
        }

        JSON.parse(response.body)['message'].should eql 'Can\'t add an enrollment to a concluded course.'
      end

      it "should not enroll a user lacking a pseudonym on the course's account" do
        foreign_user = user
        api_call_as_user @admin, :post, @path, @path_options, { :enrollment => { :user_id => foreign_user.id } }, {},
                 { expected_status: 404 }
      end

      context "custom course-level roles" do
        before :once do
          @course_role = @course.root_account.roles.build(:name => 'newrole')
          @course_role.base_role_type = 'TeacherEnrollment'
          @course_role.save!
        end

        it "should set role_name and type for a new enrollment if role is specified" do
          json = api_call :post, @path, @path_options,
          {
              :enrollment => {
                  :user_id => @unenrolled_user.id,
                  :role    => 'newrole',
                  :enrollment_state => 'active',
                  :course_section_id => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }
          Enrollment.find(json['id']).should be_an_instance_of TeacherEnrollment
          Enrollment.find(json['id']).role_name.should == 'newrole'
          json['role'].should == 'newrole'
        end

        it "should return an error if type is specified but does not the role's base_role_type" do
          json = api_call :post, @path, @path_options, {
              :enrollment => {
                  :user_id                            => @unenrolled_user.id,
                  :role                               => 'newrole',
                  :type                               => 'StudentEnrollment',
                  :enrollment_state                   => 'active',
                  :course_section_id                  => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }, {}, :expected_status => 403
          json['message'].should eql 'The specified type must match the base type for the role'
        end

        it "should return an error if role is specified but is invalid" do
          json = api_call :post, @path, @path_options, {
              :enrollment => {
                  :user_id                            => @unenrolled_user.id,
                  :role                               => 'badrole',
                  :enrollment_state                   => 'active',
                  :course_section_id                  => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }, {}, :expected_status => 403
          json['message'].should eql 'Invalid role'
        end

        it "should return an error if role is specified but is inactive" do
          @course_role.deactivate
          json = api_call :post, @path, @path_options, {
              :enrollment => {
                  :user_id                            => @unenrolled_user.id,
                  :role                               => 'newrole',
                  :enrollment_state                   => 'active',
                  :course_section_id                  => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }, {}, :expected_status => 403
          json['message'].should eql 'Cannot create an enrollment with this role because it is inactive.'
        end

        it "should return a suitable error if role is specified but is deleted" do
          @course_role.destroy
          json = api_call :post, @path, @path_options, {
              :enrollment => {
                  :user_id                            => @unenrolled_user.id,
                  :role                               => 'newrole',
                  :enrollment_state                   => 'active',
                  :course_section_id                  => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }, {}, :expected_status => 403
          json['message'].should eql 'Invalid role'
        end

        it "should accept base roles in the role parameter" do
          json = api_call :post, @path, @path_options,
              {
                  :enrollment => {
                      :user_id => @unenrolled_user.id,
                      :role => 'ObserverEnrollment',
                      :enrollment_state => 'active',
                      :course_section_id => @section.id,
                      :limit_privileges_to_course_section => true
                  }
              }
          Enrollment.find(json['id']).should be_an_instance_of ObserverEnrollment
        end

        it "should derive roles from parent accounts" do
          sub_account = Account.create!(:name => 'sub', :parent_account => @course.account)
          course(:account => sub_account)

          @course.account.roles.active.find_by_name('newrole').should be_nil
          @course.account.get_course_role('newrole').should_not be_nil

          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @path_options = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
          @section = @course.course_sections.create!

          json = api_call :post, @path, @path_options,
          {
              :enrollment => {
                  :user_id => @unenrolled_user.id,
                  :role    => 'newrole',
                  :enrollment_state => 'active',
                  :course_section_id => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }
          Enrollment.find(json['id']).should be_an_instance_of TeacherEnrollment
          Enrollment.find(json['id']).role_name.should == 'newrole'
          json['role'].should == 'newrole'
        end
      end
    end

    context "a teacher" do
      before :once do
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
          'role'                               => 'StudentEnrollment',
          'html_url'                           => course_user_url(@course, @unenrolled_user),
          'grades'                             => {
            'html_url' => course_student_grades_url(@course, @unenrolled_user),
            'final_score' => nil,
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          },
          'associated_user_id'                 => nil,
          'updated_at'                         => new_enrollment.updated_at.xmlschema,
          'created_at'                         => new_enrollment.created_at.xmlschema,
          'last_activity_at'                   => nil,
          'total_activity_time'                => 0,
          'sis_course_id'                      => @course.sis_source_id,
          'course_integration_id'              => @course.integration_id,
          'sis_section_id'                     => @section.sis_source_id,
          'section_integration_id'             => @section.integration_id,
          'start_at'                           => nil,
          'end_at'                             => nil
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
      before :once do
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

    context "self enrollment" do
      before :once do
        course(active_all: true)
        @course.update_attribute(:self_enrollment, true)
        @unenrolled_user = user_with_pseudonym
        @path = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options = {controller: 'enrollments_api', action: 'create', format: 'json', course_id: @course.id.to_s}
      end

      it "should require a logged-in user" do
        @user = nil
        raw_api_call :post, @path, @path_options,
          {
            enrollment: {
              user_id: 'self',
              self_enrollment_code: @course.self_enrollment_code
            }
          }
        response.code.should eql '401'
      end

      it "should require a valid code and user" do
        raw_api_call :post, @path, @path_options,
          {
            enrollment: {
              user_id: 'invalid',
              self_enrollment_code: 'invalid'
            }
          }
        response.code.should eql '403'
        json = JSON.parse(response.body)
        json["message"].should be_include "enrollment[self_enrollment_code] is invalid"
        json["message"].should be_include "enrollment[user_id] must be 'self' when self-enrolling"
      end

      it "should let anyone self-enroll" do
        json = api_call :post, @path, @path_options,
          {
            enrollment: {
              user_id: 'self',
              self_enrollment_code: @course.self_enrollment_code
            }
          }
        new_enrollment = Enrollment.find(json['id'])
        new_enrollment.user_id.should == @unenrolled_user.id
        new_enrollment.type.should == 'StudentEnrollment'
        new_enrollment.should be_active
        new_enrollment.should be_self_enrolled
      end
    end
  end

  describe "enrollment listing" do
    before :once do
      course_with_student(:active_all => true, :user => user_with_pseudonym)
      @teacher = User.create(:name => 'Señor Chang')
      @teacher.pseudonyms.create(:unique_id => 'chang@example.com')
      @course.enroll_teacher(@teacher)
      User.all.each { |u| u.destroy unless u.pseudonym.present? }
      @path = "/api/v1/courses/#{@course.id}/enrollments"
      @user_path = "/api/v1/users/#{@user.id}/enrollments"
      @enroll_path ="/api/v1/accounts/#{@enrollment.root_account_id}/enrollments"
      @params = { :controller => "enrollments_api", :action => "index", :course_id => @course.id.to_param, :format => "json" }
      @enroll_params = { :controller => "enrollments_api", :action => "show", :account_id => @enrollment.root_account_id, :id => @enrollment.id, :format => "json"}
      @user_params = { :controller => "enrollments_api", :action => "index", :user_id => @user.id.to_param, :format => "json" }
      @section = @course.course_sections.create!
    end

    context "an account admin" do
      before :once do
        @user = user_with_pseudonym(:username => 'admin@example.com')
        Account.default.account_users.create!(user: @user)
      end

      it "should be able to return an enrollment object by id" do
        json = api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        json.should == {
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'sis_import_id'                      => @enrollment.sis_batch_id,
            'sis_course_id'                      => nil,
            'sis_section_id'                     => nil,
            'course_integration_id'              => nil,
            'section_integration_id'             => nil,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => @enrollment.workflow_state,
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'role'                               => @enrollment.role,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
                'html_url' => course_student_grades_url(@course, @student),
                'final_score' => nil,
                'current_score' => nil,
                'final_grade' => nil,
                'current_grade' => nil,
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema,
            'created_at'                         => @enrollment.created_at.xmlschema,
            'start_at'                           => nil,
            'end_at'                             => nil,
            'last_activity_at'                   => nil,
            'total_activity_time'                => 0
        }
      end

      it "should list all of a user's enrollments in an account" do
        e = @student.current_enrollments.first
        sis_batch = e.root_account.sis_batches.create
        SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
        e.sis_batch_id = sis_batch.id
        e.save!
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.current_enrollments.includes(:user).order("users.sortable_name ASC")
        json.should == enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'sis_import_id' => sis_batch.id,
            'sis_course_id'                      => @course.sis_source_id,
            'course_integration_id'              => @course.integration_id,
            'sis_section_id'                     => @section.sis_source_id,
            'section_integration_id'             => @section.integration_id,
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
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'created_at'  => e.created_at.xmlschema,
            'start_at'  => nil,
            'end_at'  => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0
          }
        }
      end

      it "should show last_activity_at and total_activity_time for student enrollment" do
        enrollment = @course.student_enrollments.first
        enrollment.record_recent_activity(Time.zone.now - 5.minutes)
        enrollment.record_recent_activity(Time.zone.now)
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.current_enrollments.includes(:user).order("users.sortable_name ASC")
        json.should == enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'sis_import_id' => nil,
            'sis_course_id'                      => @course.sis_source_id,
            'course_integration_id'              => @course.integration_id,
            'sis_section_id'                     => @section.sis_source_id,
            'section_integration_id'             => @section.integration_id,
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
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id' => nil,
            'updated_at'         => e.updated_at.xmlschema,
            'created_at'         => e.created_at.xmlschema,
            'start_at'           => nil,
            'end_at'             => nil,
            'last_activity_at'   => e.last_activity_at.xmlschema,
            'total_activity_time' => e.total_activity_time
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

      describe "custom roles" do
        context "user context" do
          before :once do
            @original_course = @course
            course.offer!
            role = @course.account.roles.build :name => 'CustomStudent'
            role.base_role_type = 'StudentEnrollment'
            role.save!
            @course.enroll_user(@student, 'StudentEnrollment', :role_name => 'CustomStudent')
          end

          it "should include derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@user_path}?type=StudentEnrollment", @user_params.merge(:type => 'StudentEnrollment'))
            json.map{ |e| e['course_id'].to_i }.sort.should == [@original_course.id, @course.id].sort
          end

          it "should include only vanilla StudentEnrollments when called with role=StudentEnrollment" do
            json = api_call(:get, "#{@user_path}?role=StudentEnrollment", @user_params.merge(:role => 'StudentEnrollment'))
            json.map{ |e| e['course_id'].to_i }.should == [@original_course.id]
          end

          it "should filter by custom role" do
            json = api_call(:get, "#{@user_path}?role=CustomStudent", @user_params.merge(:role => 'CustomStudent'))
            json.map{ |e| e['course_id'].to_i }.should == [@course.id]
            json[0]['role'].should == 'CustomStudent'
          end

          it "should accept an array of enrollment roles" do
            json = api_call(:get, "#{@user_path}?role[]=StudentEnrollment&role[]=CustomStudent",
                            @user_params.merge(:role => %w{StudentEnrollment CustomStudent}))
            json.map{ |e| e['course_id'].to_i }.sort.should == [@original_course.id, @course.id].sort
          end
        end

        context "course context" do
          before :once do
            role = @course.account.roles.build :name => 'CustomStudent'
            role.base_role_type = 'StudentEnrollment'
            role.save!
            @original_student = @student
            student_in_course(:course => @course, :role_name => 'CustomStudent')
          end

          it "should include derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@path}?type=StudentEnrollment", @params.merge(:type => 'StudentEnrollment'))
            json.map{ |e| e['user_id'].to_i }.sort.should == [@original_student.id, @student.id].sort
          end

          it "should include only vanilla StudentEnrollments when called with role=StudentEnrollment" do
            json = api_call(:get, "#{@path}?role=StudentEnrollment", @params.merge(:role => 'StudentEnrollment'))
            json.map{ |e| e['user_id'].to_i }.should == [@original_student.id]
          end

          it "should filter by custom role" do
            json = api_call(:get, "#{@path}?role=CustomStudent", @params.merge(:role => 'CustomStudent'))
            json.map{ |e| e['user_id'].to_i }.should == [@student.id]
            json[0]['role'].should == 'CustomStudent'
          end

          it "should accept an array of enrollment roles" do
            json = api_call(:get, "#{@path}?role[]=StudentEnrollment&role[]=CustomStudent",
                            @params.merge(:role => %w{StudentEnrollment CustomStudent}))
            json.map{ |e| e['user_id'].to_i }.sort.should == [@original_student.id, @student.id].sort
          end
        end
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
          res + @course.send("#{type}_enrollments").includes(:user).order(User.sortable_name_order_by_clause("users"))
        end
        json.should == enrollments.map { |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'created_at' => e.created_at.xmlschema,
            'start_at' => nil,
            'end_at' => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0,
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
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          } if e.student? && e.user_id == @user.id
          # should not display grades for other users.
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user)
          } if e.student? && e.user_id != @user.id

          h
        }
      end

      it "should be able to return an enrollment object by id" do
        json = api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        json.should == {
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => @enrollment.workflow_state,
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'role'                               => @enrollment.role,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
                'html_url' => course_student_grades_url(@course, @student),
                'final_score' => nil,
                'current_score' => nil,
                'final_grade' => nil,
                'current_grade' => nil,
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema,
            'created_at'                         => @enrollment.created_at.xmlschema,
            'start_at'                           => nil,
            'end_at'                             => nil,
            'last_activity_at'                   => nil,
            'total_activity_time'                => 0
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
        enrollments = @user.current_enrollments.includes(:user).order("users.sortable_name ASC")
        json.should == enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role,
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
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id' => nil,
            'updated_at'         => e.updated_at.xmlschema,
            'created_at'         => e.created_at.xmlschema,
            'start_at'           => nil,
            'end_at'             => nil,
            'last_activity_at'   => nil,
            'total_activity_time' => 0
          }
        }
      end

      it "should not display grades when hide_final_grades is true for the course" do
        @course.hide_final_grades = true
        @course.save

        json = api_call(:get, @user_path, @user_params)
        json[0]['grades'].keys.should eql %w{html_url}
      end

      it "should not show enrollments for courses that aren't published" do
        course
        @course.claim
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'active')

        # Request w/o a state[] filter.
        json = api_call(:get, @user_path, @user_params)
        json.map { |e| e['id'] }.should_not include enrollment.id

        # Request w/ a state[] filter.
        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{active}, :type => %w{StudentEnrollment}))
        json.map { |e| e['id'] }.should_not include enrollment.id
      end

      it "should show enrollments for courses that aren't published if state[]=current_and_future" do
        course
        @course.claim
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'active')

        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{current_and_future}, :type => %w{StudentEnrollment}))
        json.map { |e| e['id'] }.should include enrollment.id
      end

      it "should accept multiple state[] filters" do
        course
        @course.offer!
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'completed')

        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{active completed}))
        json.map { |e| e['id'].to_i }.sort.should == @user.enrollments.map(&:id).sort
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
          res + @course.send("#{type}_enrollments").includes(:user)
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
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'user' => user_json,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'created_at' => e.created_at.xmlschema,
            'start_at' => nil,
            'end_at' => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          } if e.student?
          h
        end
      end
    end

    context "a user without permissions" do
      before :once do
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

      it "should return 401 unauthorize for a user requesting an enrollment object by id" do
        raw_api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        response.code.should eql '401'
      end
    end

    describe "pagination" do
      it "should properly paginate" do
        json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(:page => 1.to_param, :per_page => 1.to_param))
        enrollments = %w{observer student ta teacher}.inject([]) { |res, type|
          res = res + @course.send("#{type}_enrollments").includes(:user)
        }.map do |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role,
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
            'updated_at' => e.updated_at.xmlschema,
            'created_at' => e.created_at.xmlschema,
            'start_at' => nil,
            'end_at' => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          } if e.student?
          h
        end
        link_header = response.headers['Link'].split(',')
        link_header[0].should match /page=1&per_page=1/ # current page
        link_header[1].should match /page=2&per_page=1/ # next page
        link_header[2].should match /page=1&per_page=1/ # first page
        link_header[3].should match /page=2&per_page=1/ # last page
        json.should eql [enrollments[0]]

        json = api_call(:get, "#{@path}?page=2&per_page=1", @params.merge(:page => 2.to_param, :per_page => 1.to_param))
        link_header = response.headers['Link'].split(',')
        link_header[0].should match /page=2&per_page=1/ # current page
        link_header[1].should match /page=1&per_page=1/ # prev page
        link_header[2].should match /page=1&per_page=1/ # first page
        link_header[3].should match /page=2&per_page=1/ # last page
        json.should eql [enrollments[1]]
      end
    end

    describe "enrollment deletion and conclusion" do
      before :once do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
        @enrollment = @student.enrollments.first

        @teacher = User.create!(:name => 'Test Teacher')
        @teacher.pseudonyms.create!(:unique_id => 'test+teacher@example.com')
        @course.enroll_teacher(@teacher)
        @user = @teacher

        @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}"
        @params = { :controller => 'enrollments_api', :action => 'destroy', :course_id => @course.id.to_param,
          :id => @enrollment.id.to_param, :format => 'json' }
      end

      before :each do
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
            'role'                               => @enrollment.role,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
              'html_url' => course_student_grades_url(@course, @student),
              'final_score' => nil,
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema,
            'created_at'                         => @enrollment.created_at.xmlschema,
            'start_at'                           => nil,
            'end_at'                             => nil,
            'last_activity_at'                   => nil,
            'total_activity_time'                => 0
          }
        end


        it "should not be able to delete an enrollment for other courses" do
          @account = Account.default
          @sub_account = Account.create(:parent_account => @account,:name => 'English')
          @sub_account.save!
          @user = user_with_pseudonym(:username => 'sub_admin@example.com')
          @sub_account.account_users.create!(user: @user)
          @course = @sub_account.courses.create(name: 'sub')
          @course.account_id = @sub_account.id
          @course.save!

          @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}"
          @params = { :controller => 'enrollments_api', :action => 'destroy', :course_id => @course.id.to_param,
                      :id => @enrollment.id.to_param, :format => 'json' }

          raw_api_call(:delete, "#{@path}?task=delete", @params.merge(:task => 'delete'))
          response.code.should eql '404'
          JSON.parse(response.body)['errors'].should == [{ 'message' => 'The specified resource does not exist.' }]
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
            'role'                               => @enrollment.role,
            'html_url'                           => course_user_url(@course, @student),
            'grades'                             => {
              'html_url' => course_student_grades_url(@course, @student),
              'final_score' => nil,
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id'                 => @enrollment.associated_user_id,
            'updated_at'                         => @enrollment.updated_at.xmlschema,
            'created_at'                         => @enrollment.created_at.xmlschema,
            'start_at'                           => nil,
            'end_at'                             => nil,
            'last_activity_at'                   => nil,
            'total_activity_time'                => 0
          }
        end

        it "should not be able to unenroll itself if it can't re-enroll itself" do
          enrollment = @teacher.enrollments.first

          @path.sub!(@enrollment.id.to_s, enrollment.id.to_s)
          @params.merge!(:id => enrollment.id.to_param, :task => 'delete')

          raw_api_call(:delete, "#{@path}?task=delete", @params)

          response.code.should eql '401'
          JSON.parse(response.body).should == {
            'errors' => [{ 'message' => 'user not authorized to perform that action' }],
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
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'html_url' => course_user_url(@course, e.user),
            'grades' => {
              'html_url' => course_student_grades_url(@course, e.user),
              'final_score' => nil,
              'current_score' => nil,
              'final_grade' => nil,
              'current_grade' => nil,
            },
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'created_at' => e.created_at.xmlschema,
            'start_at'   => nil,
            'end_at'     => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0,
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
            'role' => e.role,
            'course_section_id' => e.course_section_id,
            'course_id' => e.course_id,
            'html_url' => course_user_url(@course, e.user),
            'associated_user_id' => nil,
            'updated_at' => e.updated_at.xmlschema,
            'created_at' => e.created_at.xmlschema,
            'start_at'   => nil,
            'end_at'     => nil,
            'last_activity_at' => nil,
            'total_activity_time' => 0,
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
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
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

