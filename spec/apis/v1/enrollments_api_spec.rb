# coding: utf-8
#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

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
        expect(json).to eq({
          'root_account_id'                    => @course.account.id,
          'id'                                 => new_enrollment.id,
          'user_id'                            => @unenrolled_user.id,
          'course_section_id'                  => @section.id,
          'limit_privileges_to_course_section' => true,
          'enrollment_state'                   => 'active',
          'course_id'                          => @course.id,
          'sis_import_id'                       => nil,
          'type'                               => 'StudentEnrollment',
          'role'                               => 'StudentEnrollment',
          'role_id'                            => student_role.id,
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
        })
        expect(new_enrollment.root_account_id).to eql @course.account.id
        expect(new_enrollment.user_id).to eql @unenrolled_user.id
        expect(new_enrollment.course_section_id).to eql @section.id
        expect(new_enrollment.limit_privileges_to_course_section).to eql true
        expect(new_enrollment.workflow_state).to eql 'active'
        expect(new_enrollment.course_id).to eql @course.id
        expect(new_enrollment.self_enrolled).to eq nil
        expect(new_enrollment).to be_an_instance_of StudentEnrollment
      end

      it "should be unauthorized for users without manage_students permission" do
        @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :manage_students)
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
                        }, {}, {:expected_status => 401}
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
        enrollment = Enrollment.find(json['id'])
        expect(enrollment).to be_an_instance_of TeacherEnrollment
        expect(enrollment.workflow_state).to eq 'active'
        expect(enrollment.course_section).to eq @section
        expect(enrollment.limit_privileges_to_course_section).to eq true
      end

      it "interprets 'false' correctly" do
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type    => 'TeacherEnrollment',
              :limit_privileges_to_course_section => 'false'
            }
          }
        expect(Enrollment.find(json['id']).limit_privileges_to_course_section).to eq false
      end

      it "adds a section limitation after the fact" do
        enrollment = @course.enroll_teacher @unenrolled_user
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type => 'TeacherEnrollment',
              :limit_privileges_to_course_section => 'true'
            }
          }
        expect(json['id']).to eq enrollment.id
        expect(enrollment.reload.limit_privileges_to_course_section).to eq true
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
        expect(Enrollment.find(json['id'])).to be_an_instance_of TaEnrollment
      end

      it "should create a new observer enrollment" do
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type    => 'ObserverEnrollment',
              :enrollment_state => 'invited',
              :course_section_id => @section.id,
              :limit_privileges_to_course_section => true
            }
          }
        enrollment = Enrollment.find(json['id'])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq 'invited'
      end

      it "should not default observer enrollments to 'active' state if the user is not registered" do
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type    => 'ObserverEnrollment',
              :course_section_id => @section.id,
              :limit_privileges_to_course_section => true
            }
          }
        enrollment = Enrollment.find(json['id'])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq 'invited'
      end

      it "should default observer enrollments to 'active' state if the user is registered" do
        @unenrolled_user.register!
        json = api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type    => 'ObserverEnrollment',
              :course_section_id => @section.id,
              :limit_privileges_to_course_section => true
            }
          }
        enrollment = Enrollment.find(json['id'])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq 'active'
      end

      it "should not create a new observer enrollment for self" do
        raw_api_call :post, @path, @path_options,
          {
            :enrollment => {
              :user_id => @unenrolled_user.id,
              :type    => 'ObserverEnrollment',
              :enrollment_state => 'active',
              :associated_user_id => @unenrolled_user.id,
              :course_section_id => @section.id,
              :limit_privileges_to_course_section => true
            }
          }

        expect(response.code).to eql '400'
        expect(JSON.parse(response.body)).to eq(
          {"errors"=>{"associated_user_id"=>[{"attribute"=>"associated_user_id", "type"=>"Cannot observe yourself", "message"=>"Cannot observe yourself"}]}}
        )
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
        expect(e.workflow_state).to eql 'invited'
        expect(e.course_section).to eql @course.default_section
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
        expect(e.workflow_state).to eql 'creation_pending'
        expect(e.course_section).to eql @course.default_section
      end

      it "should throw an error if no params are given" do
        raw_api_call :post, @path, @path_options, { :enrollment => {  } }
        expect(response.code).to eql '403'
        expect(JSON.parse(response.body)).to eq({
          'message' => 'No parameters given'
        })
      end

      it "should assume a StudentEnrollment if no type is given" do
        api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id } }
        expect(JSON.parse(response.body)['type']).to eql 'StudentEnrollment'
      end

      it "should allow creating self-enrollments" do
        json = api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, :self_enrolled => true } }
        expect(@unenrolled_user.enrollments.find(json['id']).self_enrolled).to eq(true)
      end

      it "should return an error if an invalid type is given" do
        raw_api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, :type => 'PandaEnrollment' } }
        expect(JSON.parse(response.body)['message']).to eql 'Invalid type'
      end

      it "should enroll a designer" do
        json = api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, :type => 'DesignerEnrollment' } }
        expect(json['type']).to eql 'DesignerEnrollment'
        expect(@unenrolled_user.enrollments.find(json['id'])).to be_an_instance_of(DesignerEnrollment)
      end

      it "should return an error if no user_id is given" do
        raw_api_call :post, @path, @path_options, { :enrollment => { :type => 'StudentEnrollment' } }
        expect(response.code).to eql '403'
        expect(JSON.parse(response.body)).to eq({
          'message' => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment"
        })
      end

      it "should enroll to the right section using the section-specific URL" do
        @path         = "/api/v1/sections/#{@section.id}/enrollments"
        @path_options = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :section_id => @section.id.to_s }
        json = api_call :post, @path, @path_options, { :enrollment => { :user_id => @unenrolled_user.id, } }

        expect(Enrollment.find(json['id']).course_section).to eql @section
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

        expect(JSON.parse(response.body)['message']).to eql 'Can\'t add an enrollment to a concluded course.'
      end

      it "should not allow enrollments to be added to a soft-concluded course" do
        @course.start_at = 2.days.ago
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

        expect(JSON.parse(response.body)['message']).to eql 'Can\'t add an enrollment to a concluded course.'
      end

      it "should allow enrollments to be added to an active section of a concluded course if the user is already enrolled" do
        other_section = @course.course_sections.create!
        @course.enroll_user(@unenrolled_user, "StudentEnrollment", :section => other_section)

        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @section.end_at = 1.day.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        expect(@section).to_not be_concluded
        api_call :post, @path, @path_options, {
            :enrollment => {
                :user_id                            => @unenrolled_user.id,
                :type                               => 'StudentEnrollment',
                :enrollment_state                   => 'active',
                :course_section_id                  => @section.id,
                :limit_privileges_to_course_section => true
            }
        }
      end

      it "should not allow enrollments to be added to an active section of a concluded course if the user is not already enrolled" do
        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @section.end_at = 1.day.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        raw_api_call :post, @path, @path_options, {
                              :enrollment => {
                                  :user_id                            => @unenrolled_user.id,
                                  :type                               => 'StudentEnrollment',
                                  :enrollment_state                   => 'active',
                                  :course_section_id                  => @section.id,
                                  :limit_privileges_to_course_section => true
                              }
                          }

        expect(JSON.parse(response.body)['message']).to eql 'Can\'t add an enrollment to a concluded course.'
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

        it "should set role_id and type for a new enrollment if role is specified" do
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
          expect(Enrollment.find(json['id'])).to be_an_instance_of TeacherEnrollment
          expect(Enrollment.find(json['id']).role_id).to eq @course_role.id
          expect(json['role']).to eq 'newrole'
          expect(json['role_id']).to eq @course_role.id
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
          expect(json['message']).to eql 'The specified type must match the base type for the role'
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
          expect(json['message']).to eql 'Invalid role'
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
          expect(json['message']).to eql 'Cannot create an enrollment with this role because it is inactive.'
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
          expect(json['message']).to eql 'Invalid role'
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
          expect(Enrollment.find(json['id'])).to be_an_instance_of ObserverEnrollment
        end

        it "should derive roles from parent accounts" do
          sub_account = Account.create!(:name => 'sub', :parent_account => @course.account)
          course(:account => sub_account)

          expect(@course.account.roles.active.where(:name => 'newrole').first).to be_nil
          course_role = @course.account.get_course_role_by_name('newrole')
          expect(course_role).to_not be_nil

          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @path_options = { :controller => 'enrollments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s }
          @section = @course.course_sections.create!

          json = api_call :post, @path, @path_options,
          {
              :enrollment => {
                  :user_id => @unenrolled_user.id,
                  :role_id => course_role.id,
                  :enrollment_state => 'active',
                  :course_section_id => @section.id,
                  :limit_privileges_to_course_section => true
              }
          }
          expect(Enrollment.find(json['id'])).to be_an_instance_of TeacherEnrollment
          expect(Enrollment.find(json['id']).role_id).to eq course_role.id
          expect(json['role']).to eq 'newrole'
          expect(json['role_id']).to eq course_role.id
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
        expect(json).to eq({
          'root_account_id'                    => @course.account.id,
          'id'                                 => new_enrollment.id,
          'user_id'                            => @unenrolled_user.id,
          'course_section_id'                  => @section.id,
          'limit_privileges_to_course_section' => true,
          'enrollment_state'                   => 'active',
          'course_id'                          => @course.id,
          'type'                               => 'StudentEnrollment',
          'role'                               => 'StudentEnrollment',
          'role_id'                            => student_role.id,
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
        })
        expect(new_enrollment.root_account_id).to eql @course.account.id
        expect(new_enrollment.user_id).to eql @unenrolled_user.id
        expect(new_enrollment.course_section_id).to eql @section.id
        expect(new_enrollment.limit_privileges_to_course_section).to eql true
        expect(new_enrollment.workflow_state).to eql 'active'
        expect(new_enrollment.course_id).to eql @course.id
        expect(new_enrollment).to be_an_instance_of StudentEnrollment
      end

      it "should not create an enrollment for another class" do
        raw_api_call :post, "/api/v1/courses/#{@course_wo_teacher.id}/enrollments", @path_options.merge(:course_id => @course_wo_teacher.id.to_s),
          {
            :enrollment => {
              :user_id                            => @unenrolled_user.id,
              :type                               => 'StudentEnrollment'
            }
          }
        expect(response.code).to eql '401'
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
        expect(response.code).to eql '401'
      end
    end

    context "self enrollment" do
      before :once do
        Account.default.allow_self_enrollment!
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
        expect(response.code).to eql '401'
      end

      it "should require a valid code and user" do
        raw_api_call :post, @path, @path_options,
          {
            enrollment: {
              user_id: 'invalid',
              self_enrollment_code: 'invalid'
            }
          }
        expect(response.code).to eql '403'
        json = JSON.parse(response.body)
        expect(json["message"]).to be_include "enrollment[self_enrollment_code] is invalid"
        expect(json["message"]).to be_include "enrollment[user_id] must be 'self' when self-enrolling"
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
        expect(new_enrollment.user_id).to eq @unenrolled_user.id
        expect(new_enrollment.type).to eq 'StudentEnrollment'
        expect(new_enrollment).to be_active
        expect(new_enrollment).to be_self_enrolled
      end

      it "should not let anyone self-enroll if account disables it" do
        account = @course.root_account
        account.settings.delete(:self_enrollment)
        account.save!

        json = raw_api_call :post, @path, @path_options,
                        {
                            enrollment: {
                                user_id: 'self',
                                self_enrollment_code: @course.self_enrollment_code
                            }
                        }
        expect(response.code).to eql '400'
      end
    end
  end

  describe "enrollment listing" do
    before :once do
      course_with_student(:active_all => true, :user => user_with_pseudonym)
      @group = @course.groups.create!(:name => "My Group")
      @group.add_user(@student, 'accepted', true)
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

    it "should deterministically order enrollments for pagination" do
      enrollment_num = 10
      enrollment_num.times do
        u = user_with_pseudonym(name: "John Smith", sortable_name: "Smith, John")
        @course.enroll_user(u, 'StudentEnrollment', :enrollment_state => 'active')
      end

      found_enrollment_ids = []
      enrollment_num.times do |i|
        page_num = i + 1
        json = api_call(:get, "/api/v1/courses/#{@course.id}/enrollments?page=#{page_num}&per_page=1",
          :controller=>"enrollments_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}",
          :per_page => 1, :page => page_num)

        id = json[0]["id"]
        id_already_found = found_enrollment_ids.include?(id)
        expect(id_already_found).to be_falsey
        found_enrollment_ids << id
      end
    end

    context "grading periods" do
      let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
      let(:grading_period_group) { group_helper.legacy_create_for_course(@course) }
      let(:now) { Time.zone.now }

      before :once do
        @first_grading_period = grading_period_group.grading_periods.create!(
          title: 'first',
          start_date: 2.months.ago(now),
          end_date: now
        )
        @last_grading_period = grading_period_group.grading_periods.create!(
          title: 'second',
          start_date: now,
          end_date: 2.months.from_now(now)
        )
        @assignment_in_first_period = @course.assignments.create!(
          due_at: 2.days.ago(now),
          points_possible: 10
        )
        @assignment_in_last_period = @course.assignments.create!(
          due_at: 1.day.from_now(now),
          points_possible: 10
        )
      end

      context "multiple grading periods feature flag enabled" do
        before :once do
          @course.root_account.enable_feature!(:multiple_grading_periods)
        end

        describe "user endpoint" do
          let!(:enroll_student_in_the_course) do
            student_in_course({course: @course, user: @user})
          end

          it "works for users" do
            @user_params[:grading_period_id] = @first_grading_period.id
            raw_api_call(:get, @user_path, @user_params)
            expect(response).to be_ok
          end

          it "returns an error if the user is not in the grading period" do
            course = Course.create!
            grading_period_group = group_helper.legacy_create_for_course(course)
            grading_period = grading_period_group.grading_periods.create!(
              title: "unconnected to the user's course",
              start_date: 2.months.ago,
              end_date: 2.months.from_now(now)
            )

            @user_params[:grading_period_id] = grading_period.id
            raw_api_call(:get, @user_path, @user_params)
            expect(response).to_not be_ok
          end

          describe "grade summary" do
            let!(:grade_assignments) do
              first     = @course.assignments.create! due_at: 1.month.ago
              last      = @course.assignments.create! due_at: 1.month.from_now
              no_due_at = @course.assignments.create!

              first.grade_student @user, grade: 7
              last.grade_student @user, grade: 10
              no_due_at.grade_student @user, grade: 1
            end

            describe "provides a grade summary" do

              it "for assignments due during the first grading period." do
                @user_params[:grading_period_id] = @first_grading_period.id

                raw_api_call(:get, @user_path, @user_params)
                final_score = JSON.parse(response.body).first["grades"]["final_score"]
                # ten times assignment's grade of 7
                expect(final_score).to eq 70
              end

              it "for assignments due during the last grading period." do
                @user_params[:grading_period_id] = @last_grading_period.id
                raw_api_call(:get, @user_path, @user_params)
                final_score = JSON.parse(response.body).first["grades"]["final_score"]

                # ((10 + 1) / 1) * 10 => 110
                # ((last + no_due_at) / number_of_grading_periods) * 10
                expect(final_score).to eq 110
              end

              it "for all assignments when no grading period is specified." do
                @user_params[:grading_period_id] = nil
                raw_api_call(:get, @user_path, @user_params)
                final_score = JSON.parse(response.body).first["grades"]["final_score"]

                # ((7 + 10 + 1) / 2) * 10 => 60
                # ((first + last + no_due_at) / number_of_grading_periods) * 10
                expect(final_score).to eq 90
              end
            end
          end
        end

        it "returns grades for the requested grading period for courses" do
          @assignment_in_first_period.grade_student(@student, grade: 10)
          @assignment_in_last_period.grade_student(@student, grade: 0)

          student_grade = lambda do |json|
            student_json = json.find { |e|
              e["type"] == "StudentEnrollment"
            }
            if student_json
              student_json["grades"]["final_score"]
            end
          end

          json = api_call(:get, @path, @params)
          expect(student_grade.(json)).to eq 50

          @params[:grading_period_id] = @first_grading_period.id
          json = api_call(:get, @path, @params)
          expect(student_grade.(json)).to eq 100

          @params[:grading_period_id] = @last_grading_period.id
          json =  api_call(:get, @path, @params)
          expect(student_grade.(json)).to eq 0
        end
      end

      context "multiple grading periods feature flag disabled" do
        it "should return an error message if the multiple grading periods flag is disabled" do
          @user_params[:grading_period_id] = @first_grading_period.id

          json = api_call(:get, @user_path, @user_params, {}, {}, { expected_status: 403 })
          expect(json['message']).to eq 'Multiple Grading Periods feature is disabled. Cannot filter by grading_period_id with this feature disabled'
        end
      end
    end

    context "an account admin" do
      before :once do
        @user = user_with_pseudonym(:username => 'admin@example.com')
        Account.default.account_users.create!(user: @user)
      end

      it "should be able to return an enrollment object by id" do
        json = api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        expect(json).to eq({
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
            'role'                               => @enrollment.role.name,
            'role_id'                            => @enrollment.role.id,
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
        })
      end

      it "should list all of a user's enrollments in an account" do
        e = @student.enrollments.current.first
        sis_batch = e.root_account.sis_batches.create
        SisBatch.where(id: sis_batch).update_all(workflow_state: 'imported')
        e.sis_batch_id = sis_batch.id
        e.save!
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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

      context 'group_ids' do
        it "should include a users group_ids if group_ids are in include" do
          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @params = { :controller => "enrollments_api", :action => "index", :course_id => @course.id.to_param, :format => "json", :include => ["group_ids"] }
          json = api_call(:get, @path, @params)
          expect(json[0]["user"]["group_ids"]).to eq([@group.id])
        end

        it "should not include ids from different contexts" do
          original_course = @course

          course(:active_all => true, :user => @user)
          group2 = @course.groups.create!(:name => "My Group")
          group2.add_user(@student, 'accepted', true)

          @course = original_course

          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @params = { :controller => "enrollments_api", :action => "index", :course_id => @course.id.to_param, :format => "json", :include => ["group_ids"] }
          json = api_call(:get, @path, @params)

          expect(json[0]["user"]["group_ids"]).to include(@group.id)
          expect(json[0]["user"]["group_ids"]).not_to include(group2.id)
        end
      end

      it "should show last_activity_at and total_activity_time for student enrollment" do
        enrollment = @course.student_enrollments.first
        recent_activity = Enrollment::RecentActivity.new(enrollment)
        recent_activity.record!(Time.zone.now - 5.minutes)
        recent_activity.record!(Time.zone.now)
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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
        expect(json.map { |e| e['id'] }).to include enrollment.id

        # with a state[] filter
        json = api_call(:get, "#{@user_path}?state[]=active",
                        @user_params.merge(:state => %w{active}))
        expect(json.map { |e| e['id'] }).to include enrollment.id
      end

      it "should not return enrollments from other accounts" do
        # enroll the user in a course in another account
        account = Account.create!(:name => 'Account Two')
        course = course(:account => account, :course_name => 'Account Two Course', :active_course => true)
        course.enroll_user(@student).accept!

        json = api_call(:get, @user_path, @user_params)
        expect(json.length).to eql 1
      end

      it "should list section enrollments properly" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!

        @path = "/api/v1/sections/#{@section.id}/enrollments"
        @params = { :controller => "enrollments_api", :action => "index", :section_id => @section.id.to_param, :format => "json" }
        json = api_call(:get, @path, @params)

        expect(json.length).to eql 1
        expect(json.all?{ |r| r["course_section_id"] == @section.id }).to be_truthy
      end

      it "should list deleted section enrollments properly" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!
        enrollment.destroy

        @path = "/api/v1/sections/#{@section.id}/enrollments?state[]=deleted"
        @params = { :controller => "enrollments_api", :action => "index", :section_id => @section.id.to_param, :format => "json", :state => ["deleted"] }
        json = api_call(:get, @path, @params)

        expect(json.length).to eql 1
        expect(json.all?{ |r| r["course_section_id"] == @section.id }).to be_truthy

        @path = "/api/v1/sections/#{@section.id}/enrollments"
        @params = { :controller => "enrollments_api", :action => "index", :section_id => @section.id.to_param, :format => "json" }
        json = api_call(:get, @path, @params)
        expect(json.length).to eql 0
      end

      describe "custom roles" do
        context "user context" do
          before :once do
            @original_course = @course
            course.offer!
            @role = @course.account.roles.build :name => 'CustomStudent'
            @role.base_role_type = 'StudentEnrollment'
            @role.save!
            @course.enroll_user(@student, 'StudentEnrollment', :role => @role)
          end

          it "should include derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@user_path}?type=StudentEnrollment", @user_params.merge(:type => 'StudentEnrollment'))
            expect(json.map{ |e| e['course_id'].to_i }.sort).to eq [@original_course.id, @course.id].sort
          end

          context "with role parameter" do
            it "should include only vanilla StudentEnrollments when called with role=StudentEnrollment" do
              json = api_call(:get, "#{@user_path}?role=StudentEnrollment", @user_params.merge(:role => 'StudentEnrollment'))
              expect(json.map{ |e| e['course_id'].to_i }).to eq [@original_course.id]
            end

            it "should filter by custom role" do
              json = api_call(:get, "#{@user_path}?role=CustomStudent", @user_params.merge(:role => 'CustomStudent'))
              expect(json.map{ |e| e['course_id'].to_i }).to eq [@course.id]
              expect(json[0]['role']).to eq 'CustomStudent'
            end

            it "should accept an array of enrollment roles" do
              json = api_call(:get, "#{@user_path}?role[]=StudentEnrollment&role[]=CustomStudent",
                              @user_params.merge(:role => %w{StudentEnrollment CustomStudent}))
              expect(json.map{ |e| e['course_id'].to_i }.sort).to eq [@original_course.id, @course.id].sort
            end
          end

          context "with role_id parameter" do
            it "should include only vanilla StudentEnrollments when called with built in role_id" do
              json = api_call(:get, "#{@user_path}?role_id=#{student_role.id}", @user_params.merge(:role_id => student_role.id))
              expect(json.map{ |e| e['course_id'].to_i }).to eq [@original_course.id]
            end

            it "should filter by custom role" do
              json = api_call(:get, "#{@user_path}?role_id=#{@role.id}", @user_params.merge(:role_id => @role.id))
              expect(json.map{ |e| e['course_id'].to_i }).to eq [@course.id]
              expect(json[0]['role']).to eq 'CustomStudent'
              expect(json[0]['role_id']).to eq @role.id
            end

            it "should accept an array of enrollment roles" do
              json = api_call(:get, "#{@user_path}?role_id[]=#{student_role.id}&role_id[]=#{@role.id}",
                              @user_params.merge(:role_id => [student_role.id, @role.id].map(&:to_param)))
              expect(json.map{ |e| e['course_id'].to_i }.sort).to eq [@original_course.id, @course.id].sort
            end
          end
        end

        context "course context" do
          before :once do
            role = @course.account.roles.build :name => 'CustomStudent'
            role.base_role_type = 'StudentEnrollment'
            role.save!
            @original_student = @student
            student_in_course(:course => @course, :role => role)
          end

          it "should include derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@path}?type=StudentEnrollment", @params.merge(:type => 'StudentEnrollment'))
            expect(json.map{ |e| e['user_id'].to_i }.sort).to eq [@original_student.id, @student.id].sort
          end

          it "should include only vanilla StudentEnrollments when called with role=StudentEnrollment" do
            json = api_call(:get, "#{@path}?role=StudentEnrollment", @params.merge(:role => 'StudentEnrollment'))
            expect(json.map{ |e| e['user_id'].to_i }).to eq [@original_student.id]
          end

          it "should filter by custom role" do
            json = api_call(:get, "#{@path}?role=CustomStudent", @params.merge(:role => 'CustomStudent'))
            expect(json.map{ |e| e['user_id'].to_i }).to eq [@student.id]
            expect(json[0]['role']).to eq 'CustomStudent'
          end

          it "should accept an array of enrollment roles" do
            json = api_call(:get, "#{@path}?role[]=StudentEnrollment&role[]=CustomStudent",
                            @params.merge(:role => %w{StudentEnrollment CustomStudent}))
            expect(json.map{ |e| e['user_id'].to_i }.sort).to eq [@original_student.id, @student.id].sort
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
          res + @course.send("#{type}_enrollments").eager_load(:user).order(User.sortable_name_order_by_clause("users"))
        end
        expect(json).to eq enrollments.map { |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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
        expect(json).to eq({
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => @enrollment.workflow_state,
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'role'                               => @enrollment.role.name,
            'role_id'                            => @enrollment.role.id,
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
        })
      end

      it "should filter by enrollment workflow_state" do
        @teacher.enrollments.first.update_attribute(:workflow_state, 'completed')
        json = api_call(:get, "#{@path}?state[]=completed", @params.merge(:state => %w{completed}))
        expect(json.count).to be > 0
        json.each { |e| expect(e['enrollment_state']).to eql 'completed' }
      end

      it "should list its own enrollments" do
        json = api_call(:get, @user_path, @user_params)
        enrollments = @user.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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
        expect(json[0]['grades'].keys).to eql %w{html_url}
      end

      it "should not show enrollments for courses that aren't published" do
        course
        @course.claim
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'active')

        # Request w/o a state[] filter.
        json = api_call(:get, @user_path, @user_params)
        expect(json.map { |e| e['id'] }).not_to include enrollment.id

        # Request w/ a state[] filter.
        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{active}, :type => %w{StudentEnrollment}))
        expect(json.map { |e| e['id'] }).not_to include enrollment.id
      end

      it "should show enrollments for courses that aren't published if state[]=current_and_future" do
        course
        @course.claim
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'active')

        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{current_and_future}, :type => %w{StudentEnrollment}))
        expect(json.map { |e| e['id'] }).to include enrollment.id
      end

      it "should accept multiple state[] filters" do
        course
        @course.offer!
        enrollment = course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, 'completed')

        json = api_call(:get, @user_path,
                        @user_params.merge(:state => %w{active completed}))
        expect(json.map { |e| e['id'].to_i }.sort).to eq @user.enrollments.map(&:id).sort
      end

      it "should not include the users' sis and login ids" do
        json = api_call(:get, @path, @params)
        json.each do |res|
          %w{sis_user_id sis_login_id login_id}.each { |key| expect(res['user']).not_to include(key) }
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
          res + @course.send("#{type}_enrollments").preload(:user)
        end
        expect(json).to eq(enrollments.map do |e|
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
            'role' => e.role.name,
            'role_id' => e.role.id,
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
            'total_activity_time' => 0,
            'course_integration_id' => nil,
            'sis_course_id' => nil,
            'sis_section_id' => nil,
            'section_integration_id' => nil
          }
          h['grades'] = {
            'html_url' => course_student_grades_url(@course, e.user),
            'final_score' => nil,
            'current_score' => nil,
            'final_grade' => nil,
            'current_grade' => nil,
          } if e.student?
          h
        end)
      end
    end

    context "a user without permissions" do
      before :once do
        @user = user_with_pseudonym(:name => 'Don Draper', :username => 'ddraper@sterling-cooper.com')
      end

      it "should return 401 unauthorized for a course listing" do
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/enrollments", @params.merge(:course_id => @course.id.to_param))
        expect(response.code).to eql "401"
      end

      it "should return 401 unauthorized for a user listing" do
        raw_api_call(:get, @user_path, @user_params)
        expect(response.code).to eql "401"
      end

      it "should return 401 unauthorized for a user requesting an enrollment object by id" do
        raw_api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        expect(response.code).to eql '401'
      end

      it "should return 404 for a user querying from the wrong account" do
        sub = @enrollment.root_account.sub_accounts.create!(name: "sub")
        bad_path ="/api/v1/accounts/#{sub.id}/enrollments/#{@enrollment.id}"
        enroll_params = {
          :controller => "enrollments_api",
          :action => "show",
          :account_id => sub.id,
          :id => @enrollment.id,
          :format => "json"
        }
        raw_api_call(:get, bad_path, enroll_params)
        expect(response.code).to eql '404'
      end
    end

    context "a parent observer using parent app" do
      before :once do
        @student = user(active_all: true, active_state: 'active')
        3.times do
          course
          @course.enroll_student(@student, enrollment_state: 'active')
        end
        @observer = user(active_all: true, active_state: 'active')
        @observer.user_observees.create do |uo|
          uo.user_id = @student.id
        end
        @user = @observer
        @user_path = "/api/v1/users/#{@student.id}/enrollments"
        @user_params = { :controller => "enrollments_api", :action => "index", :user_id => @student.id.to_param, :format => "json" }
      end

      it "should show all enrollments for the observee (student)" do
        json = api_call(:get, @user_path, @user_params)
        expect(json.length).to eql 3
      end

      it "should not authorize the parent to see other students' enrollments" do
        @other_student = user(active_all: true, active_state: 'active')
        @user = @observer
        path = "/api/v1/users/#{@other_student.id}/enrollments"
        params = { :controller => "enrollments_api", :action => "index", :user_id => @other_student.id.to_param, :format => "json" }
        raw_api_call(:get, path, params)
        expect(response.code).to eql '401'
      end
    end

    describe "sharding" do
      specs_require_sharding

      context "when not scoped by a user" do
        it "returns enrollments from the course's shard" do
          pend_with_bullet

          @shard1.activate { @user = user(active_user: true) }

          account_admin_user(account: @course.account, user: @user)

          json = api_call(:get, @path, @params)

          enrollment_ids = json.collect { |e| e['id'] }
          expect(enrollment_ids.sort).to eq(@course.enrollments.map(&:id).sort)
          expect(json.length).to eq 2
        end
      end

      context "when scoped by a user" do
        it "returns enrollments from all of a user's associated shards" do
          pend_with_bullet

          # create a user on a different shard
          @shard1.activate { @user = User.create!(name: 'outofshard') }

          @course.enroll_student(@user)

          # query own enrollment(s) as the out-of-shard user
          @path = "#{@path}?user_id=self"
          @params[:user_id] = 'self'

          json = api_call(:get, @path, @params)

          expect(json.length).to eq 1
          expect(json.first['course_id']).to eq(@course.id)
          expect(json.first['user_id']).to eq(@user.global_id)
        end
      end
    end

    describe "pagination" do
      it "should properly paginate" do
        json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(:page => 1.to_param, :per_page => 1.to_param))
        enrollments = %w{observer student ta teacher}.inject([]) { |res, type|
          res = res + @course.send("#{type}_enrollments").preload(:user)
        }.map do |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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
        expect(link_header[0]).to match /page=1&per_page=1/ # current page
        expect(link_header[1]).to match /page=2&per_page=1/ # next page
        expect(link_header[2]).to match /page=1&per_page=1/ # first page
        expect(link_header[3]).to match /page=2&per_page=1/ # last page
        expect(json).to eql [enrollments[0]]

        json = api_call(:get, "#{@path}?page=2&per_page=1", @params.merge(:page => 2.to_param, :per_page => 1.to_param))
        link_header = response.headers['Link'].split(',')
        expect(link_header[0]).to match /page=2&per_page=1/ # current page
        expect(link_header[1]).to match /page=1&per_page=1/ # prev page
        expect(link_header[2]).to match /page=1&per_page=1/ # first page
        expect(link_header[3]).to match /page=2&per_page=1/ # last page
        expect(json).to eql [enrollments[1]]
      end
    end

    context "inactive enrollments" do
      before do
        @inactive_user = user_with_pseudonym(:name => "Inactive User")
        student_in_course(:course => @course, :user => @inactive_user)
        @inactive_enroll = @inactive_user.enrollments.first
        @inactive_enroll.deactivate
      end

      it "excludes users with inactive enrollments for students" do
        student_in_course(:course => @course, :active_all => true, :user => user_with_pseudonym)
        json = api_call(:get, @path, @params)
        expect(json.map{ |e| e["id"] }).not_to include(@inactive_enroll.id)
      end

      it "includes users with inactive enrollments for teachers" do
        teacher_in_course(:course => @course, :active_all => true, :user => user_with_pseudonym)
        json = api_call(:get, @path, @params)
        expect(json.map{ |e| e["id"] }).to include(@inactive_enroll.id)
        enroll_json = json.detect{ |e| e["id"] == @inactive_enroll.id}
        expect(enroll_json['user_id']).to eq @inactive_user.id
        expect(enroll_json['enrollment_state']).to eq 'inactive'
      end
    end

    describe "enrollment deletion, conclusion and inactivation" do
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
          expect(json).to eq({
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => 'completed',
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'role'                               => @enrollment.role.name,
            'role_id'                            => @enrollment.role.id,
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
            'total_activity_time'                => 0,
            'course_integration_id' => nil,
            'sis_course_id' => nil,
            'sis_section_id' => nil,
            'section_integration_id' => nil
          })
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
          expect(response.code).to eql '404'
          expect(JSON.parse(response.body)['errors']).to eq [{ 'message' => 'The specified resource does not exist.' }]
        end

        it "should be able to delete an enrollment" do
          json = api_call(:delete, "#{@path}?task=delete", @params.merge(:task => 'delete'))
          @enrollment.reload
          expect(json).to eq({
            'root_account_id'                    => @enrollment.root_account_id,
            'id'                                 => @enrollment.id,
            'user_id'                            => @student.id,
            'course_section_id'                  => @enrollment.course_section_id,
            'limit_privileges_to_course_section' => @enrollment.limit_privileges_to_course_section,
            'enrollment_state'                   => 'deleted',
            'course_id'                          => @course.id,
            'type'                               => @enrollment.type,
            'role'                               => @enrollment.role.name,
            'role_id'                            => @enrollment.role.id,
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
            'total_activity_time'                => 0,
            'course_integration_id' => nil,
            'sis_course_id' => nil,
            'sis_section_id' => nil,
            'section_integration_id' => nil
          })
        end

        it "should not be able to unenroll itself if it can't re-enroll itself" do
          enrollment = @teacher.enrollments.first

          @path.sub!(@enrollment.id.to_s, enrollment.id.to_s)
          @params.merge!(:id => enrollment.id.to_param, :task => 'delete')

          raw_api_call(:delete, "#{@path}?task=delete", @params)

          expect(response.code).to eql '401'
          expect(JSON.parse(response.body)).to eq({
            'errors' => [{ 'message' => 'user not authorized to perform that action' }],
            'status'  => 'unauthorized'
          })
        end

        it "should be able to deactivate an enrollment using the 'inactivate' task" do
          json = api_call(:delete, "#{@path}?task=inactivate", @params.merge(:task => 'inactivate'))
          expect(json['enrollment_state']).to eq 'inactive'
          @enrollment.reload
          expect(@enrollment.workflow_state).to eq 'inactive'
        end

        it "should be able to deactivate an enrollment using the 'deactivate' task" do
          json = api_call(:delete, "#{@path}?task=deactivate", @params.merge(:task => 'deactivate'))
          expect(json['enrollment_state']).to eq 'inactive'
          @enrollment.reload
          expect(@enrollment.workflow_state).to eq 'inactive'
        end
      end

      context "an unauthorized user" do
        it "should return 401" do
          @user = @student
          raw_api_call(:delete, @path, @params)
          expect(response.code).to eql '401'

          raw_api_call(:delete, "#{@path}?task=delete", @params.merge(:task => 'delete'))
          expect(response.code).to eql '401'

          raw_api_call(:delete, "#{@path}?task=inactivate", @params.merge(:task => 'inactivate'))
          expect(response.code).to eql '401'

          raw_api_call(:delete, "#{@path}?task=deactivate", @params.merge(:task => 'deactivate'))
          expect(response.code).to eql '401'
        end
      end
    end

    describe "enrollment reactivation" do
      before :once do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
        teacher_in_course(:course => @course, :user => user_with_pseudonym)
        @enrollment = @student.enrollments.first
        @enrollment.deactivate

        @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reactivate"
        @params = { :controller => 'enrollments_api', :action => 'reactivate', :course_id => @course.id.to_param,
          :id => @enrollment.id.to_param, :format => 'json' }
      end

      it "should require authorization" do
        @user = @student
        raw_api_call(:put, @path, @params)
        expect(response.code).to eql '401'
      end

      it "should be able to reactivate an enrollment" do
        json = api_call(:put, @path, @params)
        expect(json['enrollment_state']).to eq 'active'
        @enrollment.reload
        expect(@enrollment.workflow_state).to eq 'active'
      end
    end

    describe "show" do
      before(:once) do
        @account = Account.default
        account_admin_user(account: @account)
        student_in_course active_all: true
        @base_path = "/api/v1/accounts/#{@account.id}/enrollments"
        @params = { :controller => 'enrollments_api', :action => 'show', :account_id => @account.to_param,
                    :format => 'json' }
      end

      context "admin" do
        before(:once) do
          @user = @admin
        end

        it "should show other's enrollment" do
          json = api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param))
          expect(json['id']).to eql(@enrollment.id)
        end
      end

      context "student" do
        before(:once) do
          @user = @student
        end

        it "should show own enrollment" do
          json = api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param))
          expect(json['id']).to eql(@enrollment.id)
        end

        it "should not show other's enrollment" do
          student = @student
          other_enrollment = student_in_course(active_all: true)
          @user = student
          api_call(:get, @base_path + "/#{other_enrollment.id}", @params.merge(id: other_enrollment.to_param), {}, {}, { expected_status: 401 })
        end
      end

      context "no user" do
        before(:once) do
          @user = nil
        end

        it "should not show enrollment" do
          json = api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param), {}, {}, { expected_status: 401 })
        end
      end
    end

    describe "filters" do
      it "should properly filter by a single enrollment type" do
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment", @params.merge(:type => %w{StudentEnrollment}))
        expect(json).to eql @course.student_enrollments.map { |e|
          {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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
        expect(json).to eq (@course.student_enrollments + @course.teacher_enrollments).map { |e|
          h = {
            'root_account_id' => e.root_account_id,
            'limit_privileges_to_course_section' => e.limit_privileges_to_course_section,
            'enrollment_state' => e.workflow_state,
            'id' => e.id,
            'user_id' => e.user_id,
            'type' => e.type,
            'role' => e.role.name,
            'role_id' => e.role.id,
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

        expect(json).to be_empty
      end
    end
  end
end

