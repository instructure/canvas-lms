# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe EnrollmentsApiController, type: :request do
  describe "enrollment creation" do
    context "an admin user" do
      before :once do
        account_admin_user(active_all: true)
        course_factory(active_course: true)
        @unenrolled_user = user_with_pseudonym
        @section         = @course.course_sections.create!
        @path            = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options    = { controller: "enrollments_api", action: "create", format: "json", course_id: @course.id.to_s }
        @user            = @admin
      end

      it "creates a new student enrollment" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "StudentEnrollment",
                            enrollment_state: "active",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true,
                            start_at: nil,
                            end_at: nil
                          }
                        }
        new_enrollment = Enrollment.find(json["id"])
        expect(json).to eq({
                             "root_account_id" => @course.account.id,
                             "id" => new_enrollment.id,
                             "user_id" => @unenrolled_user.id,
                             "course_section_id" => @section.id,
                             "limit_privileges_to_course_section" => true,
                             "enrollment_state" => "active",
                             "course_id" => @course.id,
                             "sis_import_id" => nil,
                             "type" => "StudentEnrollment",
                             "role" => "StudentEnrollment",
                             "role_id" => student_role.id,
                             "html_url" => course_user_url(@course, @unenrolled_user),
                             "grades" => {
                               "html_url" => course_student_grades_url(@course, @unenrolled_user),
                               "final_score" => nil,
                               "current_score" => nil,
                               "final_grade" => nil,
                               "current_grade" => nil,
                               "unposted_final_score" => nil,
                               "unposted_current_score" => nil,
                               "unposted_final_grade" => nil,
                               "unposted_current_grade" => nil
                             },
                             "associated_user_id" => nil,
                             "updated_at" => new_enrollment.updated_at.xmlschema,
                             "created_at" => new_enrollment.created_at.xmlschema,
                             "last_activity_at" => nil,
                             "last_attended_at" => nil,
                             "total_activity_time" => 0,
                             "sis_account_id" => @course.account.sis_source_id,
                             "sis_course_id" => @course.sis_source_id,
                             "course_integration_id" => @course.integration_id,
                             "sis_section_id" => @section.sis_source_id,
                             "sis_user_id" => @unenrolled_user.pseudonym.sis_user_id,
                             "section_integration_id" => @section.integration_id,
                             "start_at" => nil,
                             "end_at" => nil
                           })
        expect(new_enrollment.root_account_id).to eql @course.account.id
        expect(new_enrollment.user_id).to eql @unenrolled_user.id
        expect(new_enrollment.course_section_id).to eql @section.id
        expect(new_enrollment.limit_privileges_to_course_section).to be true
        expect(new_enrollment.workflow_state).to eql "active"
        expect(new_enrollment.course_id).to eql @course.id
        expect(new_enrollment.self_enrolled).to be_nil
        expect(new_enrollment).to be_an_instance_of StudentEnrollment
      end

      it "does not allow enrolling a student view student" do
        c2 = Account.default.courses.create!
        user = c2.student_view_student

        api_call :post,
                 @path,
                 @path_options,
                 {
                   enrollment: {
                     user_id: user.id,
                     type: "StudentEnrollment",
                     enrollment_state: "active",
                     course_section_id: @section.id,
                     limit_privileges_to_course_section: true,
                     start_at: nil,
                     end_at: nil
                   }
                 },
                 {},
                 expected_status: 400
        expect(@section.enrollments.count).to eq 0
      end

      it "does not allow enrolling a user as a student view student" do
        api_call :post,
                 @path,
                 @path_options,
                 {
                   enrollment: {
                     user_id: @unenrolled_user.id,
                     type: "StudentViewEnrollment",
                     enrollment_state: "active",
                     course_section_id: @section.id,
                     limit_privileges_to_course_section: true,
                     start_at: nil,
                     end_at: nil
                   }
                 },
                 {},
                 expected_status: 400
        expect(@section.enrollments.count).to eq 0
      end

      it "accepts sis_section_id" do
        @section.update_attribute(:sis_source_id, "sis_id")
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "StudentEnrollment",
                            enrollment_state: "active",
                            course_section_id: "sis_section_id:sis_id",
                            limit_privileges_to_course_section: true,
                            start_at: nil,
                            end_at: nil
                          }
                        }
        new_enrollment = Enrollment.find(json["id"])
        expect(new_enrollment.course_section).to eq @section
      end

      it "is unauthorized for users without manage_students permission (non-granular)" do
        @course.root_account.disable_feature!(:granular_permissions_manage_users)
        @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :manage_students)
        api_call :post,
                 @path,
                 @path_options,
                 {
                   enrollment: {
                     user_id: @unenrolled_user.id,
                     type: "StudentEnrollment",
                     enrollment_state: "active",
                     course_section_id: @section.id,
                     limit_privileges_to_course_section: true,
                     start_at: nil,
                     end_at: nil
                   }
                 },
                 {},
                 { expected_status: 401 }
      end

      it "is unauthorized for users without add_student_to_course permission (granular)" do
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @course.account.role_overrides.create!(role: admin_role, enabled: true, permission: :manage_students)
        @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :add_student_to_course)
        api_call :post,
                 @path,
                 @path_options,
                 {
                   enrollment: {
                     user_id: @unenrolled_user.id,
                     type: "StudentEnrollment",
                     enrollment_state: "active",
                     course_section_id: @section.id,
                     limit_privileges_to_course_section: true,
                     start_at: nil,
                     end_at: nil
                   }
                 },
                 {},
                 { expected_status: 401 }
      end

      it "creates a new teacher enrollment" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "TeacherEnrollment",
                            enrollment_state: "active",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        enrollment = Enrollment.find(json["id"])
        expect(enrollment).to be_an_instance_of TeacherEnrollment
        expect(enrollment.workflow_state).to eq "active"
        expect(enrollment.course_section).to eq @section
        expect(enrollment.limit_privileges_to_course_section).to be true
      end

      describe "temporary enrollments" do
        before(:once) do
          teacher_in_course(active_all: true)
          @account = Account.default
          @account.enable_feature!(:temporary_enrollments)
          @temporary_enrollment_pairing = TemporaryEnrollmentPairing.create!(root_account: @account, created_by: account_admin_user)
        end

        context "when feature flag is enabled" do
          it "creates a new temporary enrollment association" do
            role_id = @teacher.enrollments.take.role_id
            json = api_call_as_user @admin,
                                    :post,
                                    @path,
                                    @path_options,
                                    {
                                      enrollment: {
                                        start_at: 1.day.ago,
                                        end_at: 1.day.from_now,
                                        user_id: @unenrolled_user.id,
                                        role_id:,
                                        course_section_id: @section.id,
                                        temporary_enrollment_source_user_id: @teacher.id,
                                        temporary_enrollment_pairing_id: @temporary_enrollment_pairing.id
                                      }
                                    }
            enrollment = Enrollment.find(json["id"])
            expect(enrollment).to be_an_instance_of TeacherEnrollment
            expect(enrollment.temporary_enrollment_source_user_id).to eq @teacher.id
            expect(enrollment.temporary_enrollment_pairing_id).to be_present
          end

          it "creates a new temporary enrollment association in a sub account context" do
            sub_account = @account.sub_accounts.create!
            teacher_in_course(account: sub_account, active_all: true)
            role_id = @teacher.enrollments.take.role_id
            path = "/api/v1/courses/#{@course.id}/enrollments"
            path_options = {
              controller: "enrollments_api",
              action: "create",
              format: "json",
              course_id: @course.id.to_s
            }
            json = api_call_as_user @admin,
                                    :post,
                                    path,
                                    path_options,
                                    {
                                      enrollment: {
                                        start_at: 1.day.ago,
                                        end_at: 1.day.from_now,
                                        user_id: @unenrolled_user.id,
                                        role_id:,
                                        course_section_id: @section.id,
                                        temporary_enrollment_source_user_id: @teacher.id,
                                        temporary_enrollment_pairing_id: @temporary_enrollment_pairing.id
                                      }
                                    }
            enrollment = Enrollment.find(json["id"])
            expect(enrollment).to be_an_instance_of TeacherEnrollment
            expect(enrollment.temporary_enrollment_source_user_id).to eq @teacher.id
            expect(enrollment.temporary_enrollment_pairing_id).to be_present
          end
        end

        context "when feature flag is disabled" do
          before(:once) do
            @account.disable_feature!(:temporary_enrollments)
          end

          it "does not create a new temporary enrollment association" do
            role_id = @teacher.enrollments.take.role_id
            json = api_call_as_user @admin,
                                    :post,
                                    @path,
                                    @path_options,
                                    {
                                      enrollment: {
                                        start_at: 1.day.ago,
                                        end_at: 1.day.from_now,
                                        user_id: @unenrolled_user.id,
                                        role_id:,
                                        course_section_id: @section.id,
                                        temporary_enrollment_source_user_id: @teacher.id,
                                        temporary_enrollment_pairing_id: @temporary_enrollment_pairing.id
                                      }
                                    }
            enrollment = Enrollment.find(json["id"])
            expect(enrollment).to be_an_instance_of TeacherEnrollment
            expect(enrollment.temporary_enrollment_source_user_id).to be_nil
            expect(enrollment.temporary_enrollment_pairing_id).to be_nil
          end
        end
      end

      it "interprets 'false' correctly" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "TeacherEnrollment",
                            limit_privileges_to_course_section: "false"
                          }
                        }
        expect(Enrollment.find(json["id"]).limit_privileges_to_course_section).to be false
      end

      it "adds a section limitation after the fact" do
        enrollment = @course.enroll_teacher @unenrolled_user
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "TeacherEnrollment",
                            limit_privileges_to_course_section: "true"
                          }
                        }
        expect(json["id"]).to eq enrollment.id
        expect(enrollment.reload.limit_privileges_to_course_section).to be true
      end

      it "creates a new ta enrollment" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "TaEnrollment",
                            enrollment_state: "active",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        expect(Enrollment.find(json["id"])).to be_an_instance_of TaEnrollment
      end

      it "creates a new observer enrollment" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "ObserverEnrollment",
                            enrollment_state: "invited",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        enrollment = Enrollment.find(json["id"])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq "invited"
      end

      it "does not default observer enrollments to 'active' state if the user is not registered" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "ObserverEnrollment",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        enrollment = Enrollment.find(json["id"])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq "invited"
      end

      it "defaults observer enrollments to 'active' state if the user is registered" do
        @unenrolled_user.register!
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "ObserverEnrollment",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        enrollment = Enrollment.find(json["id"])
        expect(enrollment).to be_an_instance_of ObserverEnrollment
        expect(enrollment.workflow_state).to eq "active"
      end

      it "does not create a new observer enrollment for self" do
        raw_api_call :post,
                     @path,
                     @path_options,
                     {
                       enrollment: {
                         user_id: @unenrolled_user.id,
                         type: "ObserverEnrollment",
                         enrollment_state: "active",
                         associated_user_id: @unenrolled_user.id,
                         course_section_id: @section.id,
                         limit_privileges_to_course_section: true
                       }
                     }

        expect(response).to have_http_status :bad_request
        expect(JSON.parse(response.body)).to eq(
          { "errors" => { "associated_user_id" => [{ "attribute" => "associated_user_id", "type" => "Cannot observe yourself", "message" => "Cannot observe yourself" }] } }
        )
      end

      it "defaults new enrollments to the 'invited' state in the default section" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "StudentEnrollment"
                          }
                        }

        e = Enrollment.find(json["id"])
        expect(e.workflow_state).to eql "invited"
        expect(e.course_section).to eql @course.default_section
      end

      it "defaults new enrollments to the 'creation_pending' state for unpublished courses" do
        @course.update_attribute(:workflow_state, "claimed")
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "StudentEnrollment"
                          }
                        }

        e = Enrollment.find(json["id"])
        expect(e.workflow_state).to eql "creation_pending"
        expect(e.course_section).to eql @course.default_section
      end

      it "throws an error if no params are given" do
        raw_api_call :post, @path, @path_options, { enrollment: {} }
        expect(response).to have_http_status :bad_request
        expect(JSON.parse(response.body)).to eq({
                                                  "message" => "No parameters given"
                                                })
      end

      it "assumes a StudentEnrollment if no type is given" do
        api_call :post, @path, @path_options, { enrollment: { user_id: @unenrolled_user.id } }
        expect(JSON.parse(response.body)["type"]).to eql "StudentEnrollment"
      end

      it "allows creating self-enrollments" do
        json = api_call :post, @path, @path_options, { enrollment: { user_id: @unenrolled_user.id, self_enrolled: true } }
        expect(@unenrolled_user.enrollments.find(json["id"]).self_enrolled).to be(true)
      end

      it "returns an error if an invalid type is given" do
        raw_api_call :post, @path, @path_options, { enrollment: { user_id: @unenrolled_user.id, type: "PandaEnrollment" } }
        expect(JSON.parse(response.body)["message"]).to eql "Invalid type"
      end

      it "enrolls a designer" do
        json = api_call :post, @path, @path_options, { enrollment: { user_id: @unenrolled_user.id, type: "DesignerEnrollment" } }
        expect(json["type"]).to eql "DesignerEnrollment"
        expect(@unenrolled_user.enrollments.find(json["id"])).to be_an_instance_of(DesignerEnrollment)
      end

      it "returns an error if no user_id is given" do
        raw_api_call :post, @path, @path_options, { enrollment: { type: "StudentEnrollment" } }
        expect(response).to have_http_status :bad_request
        expect(JSON.parse(response.body)).to eq({
                                                  "message" => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment"
                                                })
      end

      it "enrolls to the right section using the section-specific URL" do
        @path         = "/api/v1/sections/#{@section.id}/enrollments"
        @path_options = { controller: "enrollments_api", action: "create", format: "json", section_id: @section.id.to_s }
        json = api_call :post, @path, @path_options, { enrollment: { user_id: @unenrolled_user.id, } }

        expect(Enrollment.find(json["id"]).course_section).to eql @section
      end

      it "does not notify by default" do
        expect_any_instance_of(StudentEnrollment).to receive(:save_without_broadcasting).at_least(:once)

        api_call(:post, @path, @path_options, {
                   enrollment: {
                     user_id: @unenrolled_user.id,
                     enrollment_state: "active"
                   }
                 })
      end

      it "optionally sends notifications" do
        expect_any_instance_of(StudentEnrollment).to receive(:save).at_least(:once)

        api_call(:post, @path, @path_options, {
                   enrollment: {
                     user_id: @unenrolled_user.id,
                     enrollment_state: "active",
                     notify: true
                   }
                 })
      end

      it "does not allow enrollments to be added to a hard-concluded course" do
        @course.complete
        raw_api_call :post, @path, @path_options, {
          enrollment: {
            user_id: @unenrolled_user.id,
            type: "StudentEnrollment",
            enrollment_state: "active",
            course_section_id: @section.id,
            limit_privileges_to_course_section: true
          }
        }

        expect(JSON.parse(response.body)["message"]).to eql "Can't add an enrollment to a concluded course."
      end

      it "does not allow enrollments to be added to a soft-concluded course" do
        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        raw_api_call :post, @path, @path_options, {
          enrollment: {
            user_id: @unenrolled_user.id,
            type: "StudentEnrollment",
            enrollment_state: "active",
            course_section_id: @section.id,
            limit_privileges_to_course_section: true
          }
        }

        expect(JSON.parse(response.body)["message"]).to eql "Can't add an enrollment to a concluded course."
      end

      it "allows enrollments to be added to an active section of a concluded course if the user is already enrolled" do
        other_section = @course.course_sections.create!
        @course.enroll_user(@unenrolled_user, "StudentEnrollment", section: other_section)

        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @section.end_at = 1.day.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        expect(@section).to_not be_concluded
        api_call :post, @path, @path_options, {
          enrollment: {
            user_id: @unenrolled_user.id,
            type: "StudentEnrollment",
            enrollment_state: "active",
            course_section_id: @section.id,
            limit_privileges_to_course_section: true
          }
        }
      end

      it "does not allow enrollments to be added to an active section of a concluded course if the user is not already enrolled" do
        @course.start_at = 2.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @section.end_at = 1.day.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        raw_api_call :post, @path, @path_options, {
          enrollment: {
            user_id: @unenrolled_user.id,
            type: "StudentEnrollment",
            enrollment_state: "active",
            course_section_id: @section.id,
            limit_privileges_to_course_section: true
          }
        }

        expect(JSON.parse(response.body)["message"]).to eql "Can't add an enrollment to a concluded course."
      end

      it "does not enroll a user lacking a pseudonym on the course's account" do
        foreign_user = user_factory
        api_call_as_user @admin,
                         :post,
                         @path,
                         @path_options,
                         { enrollment: { user_id: foreign_user.id } },
                         {},
                         { expected_status: 404 }
      end

      it "does not allow adding users to a template course" do
        @course.update!(template: true)
        api_call :post,
                 @path,
                 @path_options,
                 { enrollment: { user_id: @unenrolled_user.id } },
                 {},
                 { expected_status: 401 }
      end

      context "custom course-level roles" do
        before :once do
          @course_role = @course.root_account.roles.build(name: "newrole")
          @course_role.base_role_type = "TeacherEnrollment"
          @course_role.save!
        end

        it "sets role_id and type for a new enrollment if role is specified" do
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "newrole",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          }
          expect(Enrollment.find(json["id"])).to be_an_instance_of TeacherEnrollment
          expect(Enrollment.find(json["id"]).role_id).to eq @course_role.id
          expect(json["role"]).to eq "newrole"
          expect(json["role_id"]).to eq @course_role.id
        end

        it "returns an error if type is specified but does not the role's base_role_type" do
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "newrole",
                              type: "StudentEnrollment",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          },
                          {},
                          expected_status: 400
          expect(json["message"]).to eql "The specified type must match the base type for the role"
        end

        it "returns an error if role is specified but is invalid" do
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "badrole",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          },
                          {},
                          expected_status: 400
          expect(json["message"]).to eql "Invalid role"
        end

        it "returns an error if role is specified but is inactive" do
          @course_role.deactivate
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "newrole",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          },
                          {},
                          expected_status: 400
          expect(json["message"]).to eql "Cannot create an enrollment with this role because it is inactive."
        end

        it "returns a suitable error if role is specified but is deleted" do
          @course_role.destroy
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "newrole",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          },
                          {},
                          expected_status: 400
          expect(json["message"]).to eql "Invalid role"
        end

        it "accepts base roles in the role parameter" do
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role: "ObserverEnrollment",
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          }
          expect(Enrollment.find(json["id"])).to be_an_instance_of ObserverEnrollment
        end

        it "derives roles from parent accounts" do
          sub_account = Account.create!(name: "sub", parent_account: @course.account)
          course_factory(account: sub_account)

          expect(@course.account.roles.active.where(name: "newrole").first).to be_nil
          course_role = @course.account.get_course_role_by_name("newrole")
          expect(course_role).to_not be_nil

          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @path_options = { controller: "enrollments_api", action: "create", format: "json", course_id: @course.id.to_s }
          @section = @course.course_sections.create!

          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: @unenrolled_user.id,
                              role_id: course_role.id,
                              enrollment_state: "active",
                              course_section_id: @section.id,
                              limit_privileges_to_course_section: true
                            }
                          }
          expect(Enrollment.find(json["id"])).to be_an_instance_of TeacherEnrollment
          expect(Enrollment.find(json["id"]).role_id).to eq course_role.id
          expect(json["role"]).to eq "newrole"
          expect(json["role_id"]).to eq course_role.id
        end
      end
    end

    context "a teacher" do
      before :once do
        course_with_teacher(active_all: true)
        @course_with_teacher    = @course
        @course_wo_teacher      = course_factory
        @course                 = @course_with_teacher
        @unenrolled_user        = user_with_pseudonym
        @section                = @course.course_sections.create
        @path                   = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options           = { controller: "enrollments_api", action: "create", format: "json", course_id: @course.id.to_s }
        @user                   = @teacher
      end

      it "creates enrollments for its own class" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: @unenrolled_user.id,
                            type: "StudentEnrollment",
                            enrollment_state: "active",
                            course_section_id: @section.id,
                            limit_privileges_to_course_section: true
                          }
                        }
        new_enrollment = Enrollment.find(json["id"])
        expect(json).to eq({
                             "root_account_id" => @course.account.id,
                             "id" => new_enrollment.id,
                             "user_id" => @unenrolled_user.id,
                             "course_section_id" => @section.id,
                             "limit_privileges_to_course_section" => true,
                             "enrollment_state" => "active",
                             "course_id" => @course.id,
                             "type" => "StudentEnrollment",
                             "role" => "StudentEnrollment",
                             "role_id" => student_role.id,
                             "html_url" => course_user_url(@course, @unenrolled_user),
                             "grades" => {
                               "html_url" => course_student_grades_url(@course, @unenrolled_user),
                               "final_score" => nil,
                               "current_score" => nil,
                               "final_grade" => nil,
                               "current_grade" => nil,
                               "unposted_final_score" => nil,
                               "unposted_current_score" => nil,
                               "unposted_final_grade" => nil,
                               "unposted_current_grade" => nil
                             },
                             "associated_user_id" => nil,
                             "updated_at" => new_enrollment.updated_at.xmlschema,
                             "created_at" => new_enrollment.created_at.xmlschema,
                             "last_activity_at" => nil,
                             "last_attended_at" => nil,
                             "total_activity_time" => 0,
                             "sis_account_id" => @course.account.sis_source_id,
                             "sis_course_id" => @course.sis_source_id,
                             "course_integration_id" => @course.integration_id,
                             "sis_section_id" => @section.sis_source_id,
                             "sis_user_id" => @unenrolled_user.pseudonym.sis_user_id,
                             "section_integration_id" => @section.integration_id,
                             "start_at" => nil,
                             "end_at" => nil
                           })
        expect(new_enrollment.root_account_id).to eql @course.account.id
        expect(new_enrollment.user_id).to eql @unenrolled_user.id
        expect(new_enrollment.course_section_id).to eql @section.id
        expect(new_enrollment.limit_privileges_to_course_section).to be true
        expect(new_enrollment.workflow_state).to eql "active"
        expect(new_enrollment.course_id).to eql @course.id
        expect(new_enrollment).to be_an_instance_of StudentEnrollment
      end

      it "does not create an enrollment for another class" do
        raw_api_call :post,
                     "/api/v1/courses/#{@course_wo_teacher.id}/enrollments",
                     @path_options.merge(course_id: @course_wo_teacher.id.to_s),
                     {
                       enrollment: {
                         user_id: @unenrolled_user.id,
                         type: "StudentEnrollment"
                       }
                     }
        expect(response).to have_http_status :unauthorized
      end
    end

    context "a student" do
      before :once do
        course_with_student(active_all: true)
        @unenrolled_user        = user_with_pseudonym
        @path                   = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options           = { controller: "enrollments_api", action: "create", format: "json", course_id: @course.id.to_s }
        @user                   = @student
      end

      it "returns 401 Unauthorized" do
        raw_api_call :post,
                     @path,
                     @path_options,
                     {
                       enrollment: {
                         user_id: @unenrolled_user,
                         type: "StudentEnrollment"
                       }
                     }
        expect(response).to have_http_status :unauthorized
      end
    end

    context "self enrollment" do
      before :once do
        Account.default.allow_self_enrollment!
        course_factory(active_all: true)
        @course.update_attribute(:self_enrollment, true)
        @unenrolled_user = user_with_pseudonym
        @path = "/api/v1/courses/#{@course.id}/enrollments"
        @path_options = { controller: "enrollments_api", action: "create", format: "json", course_id: @course.id.to_s }
      end

      it "requires a logged-in user" do
        @user = nil
        raw_api_call :post,
                     @path,
                     @path_options,
                     {
                       enrollment: {
                         user_id: "self",
                         self_enrollment_code: @course.self_enrollment_code
                       }
                     }
        expect(response).to have_http_status :unauthorized
      end

      it "requires a valid code and user" do
        raw_api_call :post,
                     @path,
                     @path_options,
                     {
                       enrollment: {
                         user_id: "invalid",
                         self_enrollment_code: "invalid"
                       }
                     }
        expect(response).to have_http_status :bad_request
        json = JSON.parse(response.body)
        expect(json["message"]).to include "enrollment[self_enrollment_code] is invalid"
        expect(json["message"]).to include "enrollment[user_id] must be 'self' when self-enrolling"
      end

      it "requires the course to be in a valid state" do
        MasterCourses::MasterTemplate.set_as_master_course(@course)
        raw_api_call :post,
                     @path,
                     @path_options,
                     { enrollment: { user_id: "self", self_enrollment_code: @course.self_enrollment_code } }
        expect(response).to have_http_status :bad_request
        json = JSON.parse(response.body)
        expect(json["message"]).to include "course is not open for self-enrollment"
      end

      it "lets anyone self-enroll" do
        json = api_call :post,
                        @path,
                        @path_options,
                        {
                          enrollment: {
                            user_id: "self",
                            self_enrollment_code: @course.self_enrollment_code
                          }
                        }
        new_enrollment = Enrollment.find(json["id"])
        expect(new_enrollment.user_id).to eq @unenrolled_user.id
        expect(new_enrollment.type).to eq "StudentEnrollment"
        expect(new_enrollment).to be_active
        expect(new_enrollment).to be_self_enrolled
      end

      it "does not let anyone self-enroll if account disables it" do
        account = @course.root_account
        account.settings.delete(:self_enrollment)
        account.save!

        raw_api_call :post,
                     @path,
                     @path_options,
                     {
                       enrollment: {
                         user_id: "self",
                         self_enrollment_code: @course.self_enrollment_code
                       }
                     }
        expect(response).to have_http_status :bad_request
      end

      it "does not allow self-enrollment in a concluded course" do
        @course.update(start_at: 2.days.ago,
                       conclude_at: 1.day.ago,
                       restrict_enrollments_to_course_dates: true)
        raw_api_call :post,
                     @path,
                     @path_options,
                     { enrollment: { user_id: "self", self_enrollment_code: @course.self_enrollment_code } }
        expect(response).to have_http_status :bad_request
        expect(response.body).to include("concluded")
      end

      context "sharding" do
        specs_require_sharding

        it "groups_id retrieve correct groups with cross-shard users" do
          @shard2.activate do
            @s2_user = user_with_pseudonym(active_all: true)
          end

          @shard1.activate do
            @s1_user = user_with_pseudonym(active_all: true)
          end

          @course.enroll_student(@s1_user)
          @course.enroll_student(@s2_user)

          group = @course.groups.create(name: "A Group")

          GroupMembership.create!(
            group:,
            user: @s1_user,
            workflow_state: "accepted"
          )

          GroupMembership.create!(
            group:,
            user: @s2_user,
            workflow_state: "accepted"
          )

          json = api_call(:get, "/api/v1/courses/#{@course.id}/enrollments", { controller: "enrollments_api",
                                                                               action: "index",
                                                                               course_id: @course.id.to_param,
                                                                               format: "json",
                                                                               include: ["group_ids"] })

          expect(json[0]["user"]["group_ids"]).to eq([group.id])
          expect(json[1]["user"]["group_ids"]).to eq([group.id])
        end

        it "properly restores an existing enrollment when self-enrolling a cross-shard user" do
          @shard1.activate { @cs_user = user_with_pseudonym(active_all: true) }
          enrollment = @course.enroll_student(@cs_user)
          enrollment.destroy

          @me = @cs_user
          json = api_call :post,
                          @path,
                          @path_options,
                          {
                            enrollment: {
                              user_id: "self",
                              self_enrollment_code: @course.self_enrollment_code
                            }
                          },
                          {},
                          { expected_status: 200 }
          expect(json["id"]).to eq enrollment.id
          expect(enrollment.reload).to be_active
        end
      end
    end
  end

  describe "enrollment listing" do
    before :once do
      course_with_student(active_all: true, user: user_with_pseudonym)
      @group = @course.groups.create!(name: "My Group")
      @group.add_user(@student, "accepted", true)
      @teacher = User.create(name: "Señor Chang")
      @teacher.pseudonyms.create(unique_id: "chang@example.com")
      @course.enroll_teacher(@teacher)
      User.all.each { |u| u.destroy unless u.pseudonym.present? }
      @path = "/api/v1/courses/#{@course.id}/enrollments"
      @user_path = "/api/v1/users/#{@user.id}/enrollments"
      @enroll_path = "/api/v1/accounts/#{@enrollment.root_account_id}/enrollments"
      @params = { controller: "enrollments_api", action: "index", course_id: @course.id.to_param, format: "json" }
      @enroll_params = { controller: "enrollments_api", action: "show", account_id: @enrollment.root_account_id, id: @enrollment.id, format: "json" }
      @user_params = { controller: "enrollments_api", action: "index", user_id: @user.id.to_param, format: "json" }
      @section = @course.course_sections.create!
    end

    it "orders enrollments deterministically for pagination" do
      allow_any_instance_of(EnrollmentsApiController).to receive(:use_bookmarking?).and_return(true)
      enrollment_num = 10
      enrollment_num.times do
        u = user_with_pseudonym(name: "John Smith", sortable_name: "Smith, John")
        @course.enroll_user(u, "StudentEnrollment", enrollment_state: "active")
      end

      found_enrollment_ids = []
      enrollment_num.times do |i|
        json = if i == 0
                 api_call(:get,
                          "/api/v1/courses/#{@course.id}/enrollments?per_page=1",
                          controller: "enrollments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: 1)
               else
                 follow_pagination_link("next", { controller: "enrollments_api",
                                                  action: "index",
                                                  format: "json",
                                                  course_id: @course.id.to_s })
               end
        id = json[0]["id"]
        id_already_found = found_enrollment_ids.include?(id)
        expect(id_already_found).to be_falsey
        found_enrollment_ids << id
      end
    end

    it "orders enrollments deterministically for pagination with bookmarking not enabled" do
      allow_any_instance_of(EnrollmentsApiController).to receive(:use_bookmarking?).and_return(false)
      enrollment_num = 10
      enrollment_num.times do
        u = user_with_pseudonym(name: "John Smith", sortable_name: "Smith, John")
        @course.enroll_user(u, "StudentEnrollment", enrollment_state: "active")
      end

      found_enrollment_ids = []
      enrollment_num.times do |i|
        json = if i == 0
                 api_call(:get,
                          "/api/v1/courses/#{@course.id}/enrollments?per_page=1",
                          controller: "enrollments_api",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: 1)
               else
                 follow_pagination_link("next", { controller: "enrollments_api",
                                                  action: "index",
                                                  format: "json",
                                                  course_id: @course.id.to_s })
               end
        id = json[0]["id"]
        id_already_found = found_enrollment_ids.include?(id)
        expect(id_already_found).to be_falsey
        found_enrollment_ids << id
      end
    end

    describe "temporary enrollments" do
      let_once(:start_at) { 1.day.ago }
      let_once(:end_at) { 1.day.from_now }

      before(:once) do
        Account.default.enable_feature!(:temporary_enrollments)
        @provider = user_factory(active_all: true)
        @recipient = user_factory(active_all: true)
        course1 = course_with_teacher(active_all: true, user: @provider).course
        course2 = course_with_teacher(active_all: true, user: @provider).course
        temporary_enrollment_pairing = TemporaryEnrollmentPairing.create!(root_account: Account.default, created_by: account_admin_user)
        course1.enroll_user(
          @recipient,
          "TeacherEnrollment",
          {
            role: teacher_role,
            temporary_enrollment_source_user_id: @provider.id,
            temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
            start_at:,
            end_at:
          }
        )
        course2.enroll_user(
          @recipient,
          "TeacherEnrollment",
          {
            role: teacher_role,
            temporary_enrollment_source_user_id: @provider.id,
            temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
            start_at:,
            end_at:
          }
        )
      end

      context "when feature flag is enabled" do
        it "returns recipient temporary enrollments" do
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(temporary_enrollments_for_recipient: true,
                                                     user_id: @recipient.id))
          expect(json.length).to eq(2)
          expect(json.first["user_id"]).to eq(@recipient.id)
        end

        it "returns recipient enrollments for a provider" do
          user_path = "/api/v1/users/#{@provider.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(temporary_enrollment_recipients_for_provider: true,
                                                     user_id: @provider.id))
          expect(json.length).to eq(2)
          expect(json.first["user_id"]).to eq(@recipient.id)
        end

        it "returns default behavior if temporary enrollment args are not provided" do
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(user_id: @recipient.id))
          expect(json.length).to eq(2)
          expect(json.first["user_id"]).to eq(@recipient.id)
        end

        it "returns temporary enrollments with included providers" do
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(temporary_enrollments_for_recipient: true,
                                                     user_id: @recipient.id,
                                                     include: ["temporary_enrollment_providers"]))
          expect(json.length).to eq(2)
          expect(json.first["user_id"]).to eq(@recipient.id)
          expect(json.first["temporary_enrollment_provider"]["id"]).to eq(@provider.id)
        end

        it "respects enrollment state when a state arg is provided" do
          start_at, end_at = "2023-10-01T18:53:53Z", "2023-10-21T18:53:53Z"
          @recipient.enrollments.last.update!(start_at:, end_at:)
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(temporary_enrollments_for_recipient: true,
                                                     user_id: @recipient.id,
                                                     state: "current_and_future",
                                                     include: ["temporary_enrollment_providers"]))
          expect(json.length).to eq(1)
          expect(json.first["user_id"]).to eq(@recipient.id)
        end

        it "renders unauthorized if user is not an account admin" do
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          api_call_as_user(@provider,
                           :get,
                           user_path,
                           @user_params.merge(temporary_enrollments_for_recipient: true,
                                              user_id: @recipient.id))
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when feature flag is disabled" do
        before(:once) do
          Account.default.disable_feature!(:temporary_enrollments)
        end

        it "ignores temp enrollment params and returns default enrollment behavior" do
          user_path = "/api/v1/users/#{@recipient.id}/enrollments"
          json = api_call_as_user(account_admin_user,
                                  :get,
                                  user_path,
                                  @user_params.merge(temporary_enrollments_for_recipient: true,
                                                     user_id: @recipient.id))
          expect(json.length).to eq(2)
          expect(json.first["user_id"]).to eq(@recipient.id)
        end
      end
    end

    it "supports course SIS IDs with slashes, question marks, and periods" do
      @course.update! sis_source_id: "some_sis_id/with?slashes.andstuff"
      @path = "/api/v1/courses/sis_course_id:some_sis_id%2Fwith%3Fslashes.andstuff/enrollments"
      # Can't use api_call(), as that checks whether the course's (numeric) id matches
      # up with the param (in this case, "sis_source:with...")
      headers = { HTTP_AUTHORIZATION: "Bearer #{access_token_for_user(@user)}" }
      get @path, headers:, params: @params
      expect(response).to have_http_status(:ok)
      results = JSON.parse(response.body)
      expect(results.pluck("course_id").uniq).to eq([@course.id])
    end

    context "filtering by SIS IDs" do
      it "returns an error message with insufficient permissions" do
        @params[:sis_user_id] = "12345"

        json = api_call(:get, @path, @params, {}, {}, { expected_status: 400 })
        expect(json["message"]).to eq "Insufficient permissions to filter by SIS fields"
      end
    end

    context "grading periods" do
      let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
      let(:grading_period_group) { group_helper.legacy_create_for_course(@course) }
      let(:now) { Time.zone.now }

      before :once do
        @first_grading_period = grading_period_group.grading_periods.create!(
          title: "first",
          start_date: 2.months.ago(now),
          end_date: now
        )
        @last_grading_period = grading_period_group.grading_periods.create!(
          title: "second",
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

      describe "user endpoint" do
        let!(:enroll_student_in_the_course) do
          student_in_course({ course: @course, user: @user })
        end

        it "works for users" do
          @user_params[:grading_period_id] = @first_grading_period.id
          raw_api_call(:get, @user_path, @user_params)
          expect(response).to be_ok
        end

        it "filters to terms for users" do
          term = EnrollmentTerm.create!(name: "fall", root_account_id: @course.root_account_id)
          course = Course.create!(enrollment_term_id: term.id, root_account_id: @course.root_account_id, workflow_state: "available")
          e = course.enroll_user(@student)
          @user_params[:enrollment_term_id] = term.id
          json = api_call(:get, @user_path, @user_params)
          expect(json.length).to eq(1)
          expect(json.first["id"]).to eq e.id
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
          expect(response).not_to be_ok
        end

        it "excludes soft-concluded courses when using state[]=invited or active" do
          course0 = @course

          course_with_student user: @student, enrollment_state: "invited", active_course: true
          json = api_call_as_user @student, :get, @user_path, @user_params.merge(state: %w[invited active])
          expect(json.pluck("course_id")).to match_array [course0.id, @course.id]

          @course.start_at = 1.month.ago
          @course.conclude_at = 1.week.ago
          @course.restrict_enrollments_to_course_dates = true
          @course.save!
          json = api_call_as_user @student, :get, @user_path, @user_params.merge(state: %w[invited active])
          expect(json.pluck("course_id")).to match_array [course0.id]
        end

        it "returns error when using an invalid state" do
          course_with_student user: @student, enrollment_state: "invited", active_course: true
          json = api_call_as_user @student, :get, @user_path, @user_params.merge(state: %w[invalid_state])

          expect(json["error"]).to eq("Invalid state invalid_state")
        end

        describe "grade summary" do
          let!(:grade_assignments) do
            first     = @course.assignments.create! due_at: 1.month.ago
            last      = @course.assignments.create! due_at: 1.month.from_now
            no_due_at = @course.assignments.create!

            Timecop.freeze(@first_grading_period.end_date - 1.day) do
              first.grade_student @user, grade: 7, grader: @teacher
            end
            last.grade_student @user, grade: 10, grader: @teacher
            no_due_at.grade_student @user, grade: 1, grader: @teacher
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

        describe "grading period scores" do
          let(:observer) { User.create! }

          student_grade = lambda do |json|
            student_json = json.find do |e|
              e["type"] == "StudentEnrollment"
            end
            if student_json
              student_json["grades"]["final_score"]
            end
          end

          before do
            Timecop.freeze(@first_grading_period.end_date - 1.day) do
              @assignment_in_first_period.grade_student(@student, grade: 10, grader: @teacher)
            end
            @assignment_in_last_period.grade_student(@student, grade: 0, grader: @teacher)
          end

          it "returns grades for the requested grading period for courses" do
            json = api_call(:get, @path, @params)
            expect(student_grade.call(json)).to eq 50

            @params[:grading_period_id] = @first_grading_period.id
            json = api_call(:get, @path, @params)
            expect(student_grade.call(json)).to eq 100

            @params[:grading_period_id] = @last_grading_period.id
            json = api_call(:get, @path, @params)
            expect(student_grade.call(json)).to eq 0
          end

          it "includes observee grades when observed_users are requested" do
            @course.enroll_user(observer, "ObserverEnrollment", associated_user_id: @student.id)
            @params[:include] = ["observed_users"]
            json = api_call_as_user(observer, :get, @path, @params)
            expect(student_grade.call(json)).to eq 50

            @params[:grading_period_id] = @first_grading_period.id
            json = api_call_as_user(observer, :get, @path, @params)
            expect(student_grade.call(json)).to eq 100

            @params[:grading_period_id] = @last_grading_period.id
            json = api_call_as_user(observer, :get, @path, @params)
            expect(student_grade.call(json)).to eq 0
          end
        end
      end
    end

    context "an account admin" do
      before :once do
        @user = user_with_pseudonym(username: "admin@example.com")
        Account.default.account_users.create!(user: @user)
      end

      it "is able to request enrollments for a specific user in a course" do
        @params[:user_id] = @student.id
        api_call_as_user(@user, :get, @path, @params)
        expect(response).to be_successful
      end

      it "is able to return an enrollment object by id" do
        json = api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        expect(json).to eq({
                             "root_account_id" => @enrollment.root_account_id,
                             "id" => @enrollment.id,
                             "user_id" => @student.id,
                             "course_section_id" => @enrollment.course_section_id,
                             "sis_import_id" => @enrollment.sis_batch_id,
                             "sis_account_id" => nil,
                             "sis_course_id" => nil,
                             "sis_section_id" => nil,
                             "sis_user_id" => nil,
                             "course_integration_id" => nil,
                             "section_integration_id" => nil,
                             "limit_privileges_to_course_section" => @enrollment.limit_privileges_to_course_section,
                             "enrollment_state" => @enrollment.workflow_state,
                             "course_id" => @course.id,
                             "type" => @enrollment.type,
                             "role" => @enrollment.role.name,
                             "role_id" => @enrollment.role.id,
                             "html_url" => course_user_url(@course, @student),
                             "grades" => {
                               "html_url" => course_student_grades_url(@course, @student),
                               "final_score" => nil,
                               "current_score" => nil,
                               "final_grade" => nil,
                               "current_grade" => nil,
                               "unposted_final_score" => nil,
                               "unposted_current_score" => nil,
                               "unposted_final_grade" => nil,
                               "unposted_current_grade" => nil
                             },
                             "associated_user_id" => @enrollment.associated_user_id,
                             "updated_at" => @enrollment.updated_at.xmlschema,
                             "created_at" => @enrollment.created_at.xmlschema,
                             "start_at" => nil,
                             "end_at" => nil,
                             "last_activity_at" => nil,
                             "last_attended_at" => nil,
                             "total_activity_time" => 0
                           })
      end

      it "lists all of a user's enrollments in an account" do
        enrollment = @student.enrollments.current.first
        sis_batch = enrollment.root_account.sis_batches.create
        SisBatch.where(id: sis_batch).update_all(workflow_state: "imported")
        enrollment.sis_batch_id = sis_batch.id
        enrollment.save!
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq(enrollments.map do |e|
          {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "sis_import_id" => sis_batch.id,
            "sis_account_id" => @course.account.sis_source_id,
            "sis_course_id" => @course.sis_source_id,
            "course_integration_id" => @course.integration_id,
            "sis_section_id" => @section.sis_source_id,
            "sis_user_id" => @student.pseudonym.sis_user_id,
            "section_integration_id" => @section.integration_id,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "sis_user_id" => nil,
              "integration_id" => nil,
              "sis_import_id" => nil,
              "id" => e.user.id,
              "created_at" => e.user.created_at.iso8601,
              "login_id" => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
            },
            "html_url" => course_user_url(e.course_id, e.user_id),
            "grades" => {
              "html_url" => course_student_grades_url(e.course_id, e.user_id),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
              "unposted_final_score" => nil,
              "unposted_current_score" => nil,
              "unposted_final_grade" => nil,
              "unposted_current_grade" => nil
            },
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "last_activity_at" => nil,
            "last_attended_at" => nil,
            "total_activity_time" => 0
          }
        end)
      end

      context "filtering by SIS IDs" do
        context "filtering by sis_account_id" do
          before(:once) do
            root_account_id = @course.account.id

            @subaccount = Account.create!(parent_account_id: root_account_id)
            @subaccount.root_account_id = root_account_id
            @subaccount.sis_source_id = "1234"
            @subaccount.save!

            @course.update_attribute(:account_id, @subaccount.id)
          end

          it "filters by a single sis_account_id" do
            @params[:sis_account_id] = "1234"
            json = api_call(:get, @path, @params)
            student_ids = json.pluck("user_id")
            expect(json.length).to eq(2)
            expect(json.first["sis_account_id"]).to eq(@subaccount.sis_source_id)
            expect(student_ids).to match_array([@teacher.id, @student.id])
          end

          it "filters by a list of sis_account_ids" do
            @params[:sis_account_id] = ["1234", "5678"]
            json = api_call(:get, @path, @params)
            student_ids = json.pluck("user_id")
            expect(json.length).to eq(2)
            expect(json.first["sis_account_id"]).to eq(@subaccount.sis_source_id)
            expect(student_ids).to match_array([@teacher.id, @student.id])
          end

          it "returns nothing if there are no matching sis_account_ids" do
            @params[:sis_account_id] = "5678"
            json = api_call(:get, @path, @params)
            expect(json).to be_empty
          end
        end

        context "filtering by sis_user_id" do
          before :once do
            account_admin_user(active_all: true)
            @teacher.pseudonym.update_attribute(:sis_user_id, "1234")
          end

          it "filters by a single sis_user_id" do
            @params[:sis_user_id] = "1234"
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(1)
            expect(json.first["sis_user_id"]).to eq(@teacher.pseudonym.sis_user_id)
          end

          it "filters enrollments not made with sis_user_id" do
            section = @course.course_sections.create!(name: "other_section")
            e = section.enroll_user(@teacher, "TeacherEnrollment")
            # generally these are populated from a sis_import
            Enrollment.where(id: e).update_all(sis_pseudonym_id: @teacher.pseudonyms.where(sis_user_id: "1234").take.id)
            @params[:sis_user_id] = "1234"
            @params[:created_for_sis_id] = true
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(1)
            expect(json.first["id"]).to eq(e.id)
          end

          it "filters by a list of sis_user_ids" do
            @params[:sis_user_id] = ["1234", "5678"]
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(1)
            expect(json.first["sis_user_id"]).to eq(@teacher.pseudonym.sis_user_id)
          end

          it "returns nothing if there are no matching sis_user_ids" do
            @params[:sis_user_id] = "5678"
            json = api_call(:get, @path, @params)
            expect(json).to be_empty
          end

          it "will include inactive enrollment states by default" do
            inactive_user = user_with_pseudonym(active_user: true, sis_user_id: "abc123")
            invited_user = user_with_pseudonym(active_user: true, sis_user_id: "def456")
            completed_user = user_with_pseudonym(active_user: true, sis_user_id: "ghi789")
            @course.enroll_user(inactive_user, "StudentEnrollment", enrollment_state: "inactive")
            @course.enroll_user(invited_user, "StudentEnrollment", enrollment_state: "invited")
            @course.enroll_user(completed_user, "StudentEnrollment", enrollment_state: "completed")
            @params[:sis_user_id] = %w[1234 abc123 def456 ghi789]
            user_session(@admin)
            json = api_call_as_user(@admin, :get, @path, @params)
            # includes active, invited, and inactive states
            expect(json.length).to eq(3)
          end

          it "will support the enrollment :state param if provided" do
            active_user1 = user_with_pseudonym(active_user: true, sis_user_id: "abc123")
            active_user2 = user_with_pseudonym(active_user: true, sis_user_id: "def456")
            invited_user = user_with_pseudonym(active_user: true, sis_user_id: "ghi789")
            inactive_user = user_with_pseudonym(active_user: true, sis_user_id: "jkl101")
            @course.enroll_user(active_user1, "StudentEnrollment", enrollment_state: "active")
            @course.enroll_user(active_user2, "StudentEnrollment", enrollment_state: "active")
            @course.enroll_user(invited_user, "StudentEnrollment", enrollment_state: "invited")
            @course.enroll_user(inactive_user, "StudentEnrollment", enrollment_state: "inactive")
            @params[:state] = "active"
            @params[:sis_user_id] = %w[abc123 def456 ghi789 jkl101]
            user_session(@admin)
            json = api_call_as_user(@admin, :get, @path, @params)
            # includes only active state enrollments
            expect(json.length).to eq(2)
          end
        end

        context "filtering by sis_section_id" do
          before :once do
            @course.course_sections.first.update_attribute(:sis_source_id, "SIS123")
          end

          it "filters by a single sis_section_id" do
            @params[:sis_section_id] = "SIS123"
            json = api_call(:get, @path, @params)
            json_user_ids = json.pluck("user_id")
            section_user_ids = @course.course_sections.first.enrollments.map(&:user_id)
            expect(json.length).to eq(@course.course_sections.first.enrollments.length)
            expect(json_user_ids).to match_array(section_user_ids)
          end

          it "filters by a list of sis_section_ids" do
            @params[:sis_section_id] = ["SIS123", "SIS456"]
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(@course.course_sections.first.enrollments.length)
            json_user_ids = json.pluck("user_id")
            section_user_ids = @course.course_sections.first.enrollments.map(&:user_id)
            expect(json_user_ids).to match_array(section_user_ids)
          end

          it "returns nothing if there are no matching sis_section_ids" do
            @params[:sis_section_id] = "5678"
            json = api_call(:get, @path, @params)
            expect(json).to be_empty
          end
        end

        context "filtering by sis_course_id" do
          before :once do
            @course.update_attribute(:sis_source_id, "SIS123")
          end

          it "filters by a single sis_course_id" do
            @params[:sis_course_id] = "SIS123"
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(@course.enrollments.length)
            json_user_ids = json.pluck("user_id")
            course_user_ids = @course.enrollments.map(&:user_id)
            expect(json_user_ids).to match_array(course_user_ids)
          end

          it "filters by a list of sis_course_ids" do
            @params[:sis_course_id] = ["SIS123", "LULZ"]
            json = api_call(:get, @path, @params)
            expect(json.length).to eq(@course.enrollments.length)
            json_user_ids = json.pluck("user_id")
            course_user_ids = @course.enrollments.map(&:user_id)
            expect(json_user_ids).to match_array(course_user_ids)
          end

          it "returns nothing if there are no matching sis_course_ids" do
            @params[:sis_course_id] = "NONONO"
            json = api_call(:get, @path, @params)
            expect(json).to be_empty
          end
        end
      end

      context "group_ids" do
        it "includes a users group_ids if group_ids are in include" do
          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @params = { controller: "enrollments_api", action: "index", course_id: @course.id.to_param, format: "json", include: ["group_ids"] }
          enrollments_json = api_call(:get, @path, @params)
          expect(enrollments_json[0]["user"]["group_ids"]).to eq([@group.id])
        end

        it "does not include a users deleted memberships" do
          @group.group_memberships.update_all(workflow_state: "deleted")
          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @params = { controller: "enrollments_api", action: "index", course_id: @course.id.to_param, format: "json", include: ["group_ids"] }
          json = api_call(:get, @path, @params)
          expect(json[0]["user"]["group_ids"]).to be_empty
        end

        it "does not include ids from different contexts" do
          original_course = @course

          course_factory(active_all: true, user: @user)
          group2 = @course.groups.create!(name: "My Group")
          group2.add_user(@student, "accepted", true)

          @course = original_course

          @path = "/api/v1/courses/#{@course.id}/enrollments"
          @params = { controller: "enrollments_api", action: "index", course_id: @course.id.to_param, format: "json", include: ["group_ids"] }
          enrollments_json = api_call(:get, @path, @params)

          expect(enrollments_json[0]["user"]["group_ids"]).to include(@group.id)
          expect(enrollments_json[0]["user"]["group_ids"]).not_to include(group2.id)
        end
      end

      it "shows last_activity_at and total_activity_time for student enrollment" do
        enrollment = @course.student_enrollments.first
        recent_activity = Enrollment::RecentActivity.new(enrollment)
        recent_activity.record!(5.minutes.ago)
        recent_activity.record!(Time.zone.now)
        json = api_call(:get, @user_path, @user_params)
        enrollments = @student.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq(enrollments.map do |e|
          {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "sis_import_id" => nil,
            "sis_account_id" => @course.account.sis_source_id,
            "sis_course_id" => @course.sis_source_id,
            "course_integration_id" => @course.integration_id,
            "sis_section_id" => @section.sis_source_id,
            "sis_user_id" => @student.pseudonym.sis_user_id,
            "section_integration_id" => @section.integration_id,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "sis_user_id" => e.user.pseudonym ? e.user.pseudonym&.sis_user_id : nil,
              "integration_id" => e.user.pseudonym ? e.user.pseudonym&.integration_id : nil,
              "sis_import_id" => e.user.pseudonym ? e.user.pseudonym.sis_batch_id : nil,
              "id" => e.user.id,
              "created_at" => e.user.created_at.iso8601,
              "login_id" => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
            },
            "html_url" => course_user_url(e.course_id, e.user_id),
            "grades" => {
              "html_url" => course_student_grades_url(e.course_id, e.user_id),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
              "unposted_current_score" => nil,
              "unposted_current_grade" => nil,
              "unposted_final_score" => nil,
              "unposted_final_grade" => nil
            },
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "last_activity_at" => e.last_activity_at.xmlschema,
            "last_attended_at" => nil,
            "total_activity_time" => e.total_activity_time
          }
        end)
      end

      it "returns enrollments for unpublished courses" do
        course_factory
        @course.claim
        enrollment = course_factory.enroll_student(@student)
        enrollment.update_attribute(:workflow_state, "active")

        # without a state[] filter
        json = api_call(:get, @user_path, @user_params)
        expect(json.pluck("id")).to include enrollment.id

        # with a state[] filter
        json = api_call(:get,
                        "#{@user_path}?state[]=active",
                        @user_params.merge(state: %w[active]))
        expect(json.pluck("id")).to include enrollment.id
      end

      it "does not return enrollments from other accounts" do
        # enroll the user in a course in another account
        account = Account.create!(name: "Account Two")
        course = course_factory(account:, course_name: "Account Two Course", active_course: true)
        course.enroll_user(@student).accept!

        json = api_call(:get, @user_path, @user_params)
        expect(json.length).to be 1
      end

      it "lists section enrollments properly" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!

        @path = "/api/v1/sections/#{@section.id}/enrollments"
        @params = { controller: "enrollments_api", action: "index", section_id: @section.id.to_param, format: "json" }
        json = api_call(:get, @path, @params)

        expect(json.length).to be 1
        expect(json.all? { |r| r["course_section_id"] == @section.id }).to be_truthy
      end

      it "lists deleted section enrollments properly" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!
        enrollment.destroy

        @path = "/api/v1/sections/#{@section.id}/enrollments?state[]=deleted"
        @params = { controller: "enrollments_api", action: "index", section_id: @section.id.to_param, format: "json", state: ["deleted"] }
        json = api_call(:get, @path, @params)

        expect(json.length).to be 1
        expect(json.all? { |r| r["course_section_id"] == @section.id }).to be_truthy

        @path = "/api/v1/sections/#{@section.id}/enrollments"
        @params = { controller: "enrollments_api", action: "index", section_id: @section.id.to_param, format: "json" }
        json = api_call(:get, @path, @params)
        expect(json.length).to be 0
      end

      it "lists enrollments in deleted sections as deleted" do
        enrollment = @student.enrollments.first
        enrollment.course_section = @section
        enrollment.save!
        CourseSection.where(id: @section.id).update_all(workflow_state: "deleted")

        path = "/api/v1/users/#{@student.id}/enrollments"
        params = { controller: "enrollments_api", action: "index", user_id: @student.id.to_param, format: "json" }
        json = api_call(:get, path, params)

        expect(json.first["enrollment_state"]).to eql "deleted"
      end

      describe "no associated accounts" do
        before :once do
          @student.pseudonyms.destroy_all
          @student.user_account_associations.destroy_all
        end

        it "returns an empty array when caller has read roster rights but target user has no associated accounts" do
          path = "/api/v1/users/#{@student.id}/enrollments"
          params = { controller: "enrollments_api", action: "index", user_id: @student.id.to_param, format: "json" }
          json = api_call(:get, path, params)

          expect(json).to be_empty
        end

        it "returns unauthorized when caller doesn't have read roster rights and target user has no associated accounts" do
          @observer = user_factory

          path = "/api/v1/users/#{@student.id}/enrollments"
          params = { controller: "enrollments_api", action: "index", user_id: @student.id.to_param, format: "json" }
          api_call_as_user(@observer, :get, path, params)

          expect(response).to have_http_status :unauthorized
        end
      end

      describe "custom roles" do
        context "user context" do
          before :once do
            @original_course = @course
            course_factory.offer!
            @role = @course.account.roles.build name: "CustomStudent"
            @role.base_role_type = "StudentEnrollment"
            @role.save!
            @course.enroll_user(@student, "StudentEnrollment", role: @role)
          end

          it "includes derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@user_path}?type=StudentEnrollment", @user_params.merge(type: "StudentEnrollment"))
            expect(json.map { |e| e["course_id"].to_i }.sort).to eq [@original_course.id, @course.id].sort
          end

          context "with role parameter" do
            it "includes only vanilla StudentEnrollments when called with role=StudentEnrollment" do
              json = api_call(:get, "#{@user_path}?role=StudentEnrollment", @user_params.merge(role: "StudentEnrollment"))
              expect(json.map { |e| e["course_id"].to_i }).to eq [@original_course.id]
            end

            it "filters by custom role" do
              json = api_call(:get, "#{@user_path}?role=CustomStudent", @user_params.merge(role: "CustomStudent"))
              expect(json.map { |e| e["course_id"].to_i }).to eq [@course.id]
              expect(json[0]["role"]).to eq "CustomStudent"
            end

            it "accepts an array of enrollment roles" do
              json = api_call(:get,
                              "#{@user_path}?role[]=StudentEnrollment&role[]=CustomStudent",
                              @user_params.merge(role: %w[StudentEnrollment CustomStudent]))
              expect(json.map { |e| e["course_id"].to_i }.sort).to eq [@original_course.id, @course.id].sort
            end
          end

          context "with role_id parameter" do
            it "includes only vanilla StudentEnrollments when called with built in role_id" do
              json = api_call(:get, "#{@user_path}?role_id=#{student_role.id}", @user_params.merge(role_id: student_role.id))
              expect(json.map { |e| e["course_id"].to_i }).to eq [@original_course.id]
            end

            it "filters by custom role" do
              json = api_call(:get, "#{@user_path}?role_id=#{@role.id}", @user_params.merge(role_id: @role.id))
              expect(json.map { |e| e["course_id"].to_i }).to eq [@course.id]
              expect(json[0]["role"]).to eq "CustomStudent"
              expect(json[0]["role_id"]).to eq @role.id
            end

            it "accepts an array of enrollment roles" do
              json = api_call(:get,
                              "#{@user_path}?role_id[]=#{student_role.id}&role_id[]=#{@role.id}",
                              @user_params.merge(role_id: [student_role.id, @role.id].map(&:to_param)))
              expect(json.map { |e| e["course_id"].to_i }.sort).to eq [@original_course.id, @course.id].sort
            end
          end
        end

        context "course context" do
          before :once do
            role = @course.account.roles.build name: "CustomStudent"
            role.base_role_type = "StudentEnrollment"
            role.save!
            @original_student = @student
            student_in_course(course: @course, role:)
          end

          it "includes derived roles when called with type=StudentEnrollment" do
            json = api_call(:get, "#{@path}?type=StudentEnrollment", @params.merge(type: "StudentEnrollment"))
            expect(json.map { |e| e["user_id"].to_i }.sort).to eq [@original_student.id, @student.id].sort
          end

          it "includes only vanilla StudentEnrollments when called with role=StudentEnrollment" do
            json = api_call(:get, "#{@path}?role=StudentEnrollment", @params.merge(role: "StudentEnrollment"))
            expect(json.map { |e| e["user_id"].to_i }).to eq [@original_student.id]
          end

          it "filters by custom role" do
            json = api_call(:get, "#{@path}?role=CustomStudent", @params.merge(role: "CustomStudent"))
            expect(json.map { |e| e["user_id"].to_i }).to eq [@student.id]
            expect(json[0]["role"]).to eq "CustomStudent"
          end

          it "accepts an array of enrollment roles" do
            json = api_call(:get,
                            "#{@path}?role[]=StudentEnrollment&role[]=CustomStudent",
                            @params.merge(role: %w[StudentEnrollment CustomStudent]))
            expect(json.map { |e| e["user_id"].to_i }.sort).to eq [@original_student.id, @student.id].sort
          end
        end
      end
    end

    context "a student" do
      it "lists all members of a course" do
        current_user = @user
        enrollment = @course.enroll_user(user_factory)
        enrollment.accept!

        @user = current_user
        json = api_call(:get, @path, @params)
        enrollments = %w[observer student ta teacher].inject([]) do |res, type|
          res + @course.send(:"#{type}_enrollments").eager_load(:user).order(User.sortable_name_order_by_clause("users"))
        end
        expect(json).to match_array(enrollments.map do |e|
          h = {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "html_url" => course_user_url(@course, e.user),
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "id" => e.user.id,
              "created_at" => e.user.created_at.iso8601
            }
          }
          # should display the user's own grades
          if e.student? && e.user_id == @user.id
            h["grades"] = {
              "html_url" => course_student_grades_url(@course, e.user),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
            }
          end
          # should not display grades for other users.
          if e.student? && e.user_id != @user.id
            h["grades"] = {
              "html_url" => course_student_grades_url(@course, e.user)
            }
          end
          if e.user == @user
            h.merge!(
              "last_activity_at" => nil,
              "last_attended_at" => nil,
              "total_activity_time" => 0
            )
          end

          h
        end)
      end

      it "is able to return an enrollment object by id" do
        json = api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        expect(json).to eq({
                             "root_account_id" => @enrollment.root_account_id,
                             "id" => @enrollment.id,
                             "user_id" => @student.id,
                             "course_section_id" => @enrollment.course_section_id,
                             "limit_privileges_to_course_section" => @enrollment.limit_privileges_to_course_section,
                             "enrollment_state" => @enrollment.workflow_state,
                             "course_id" => @course.id,
                             "type" => @enrollment.type,
                             "role" => @enrollment.role.name,
                             "role_id" => @enrollment.role.id,
                             "html_url" => course_user_url(@course, @student),
                             "grades" => {
                               "html_url" => course_student_grades_url(@course, @student),
                               "final_score" => nil,
                               "current_score" => nil,
                               "final_grade" => nil,
                               "current_grade" => nil,
                             },
                             "associated_user_id" => @enrollment.associated_user_id,
                             "updated_at" => @enrollment.updated_at.xmlschema,
                             "created_at" => @enrollment.created_at.xmlschema,
                             "start_at" => nil,
                             "end_at" => nil,
                             "last_activity_at" => nil,
                             "last_attended_at" => nil,
                             "total_activity_time" => 0
                           })
      end

      it "filters by enrollment workflow_state" do
        @teacher.enrollments.first.update_attribute(:workflow_state, "completed")
        json = api_call(:get, "#{@path}?state[]=completed", @params.merge(state: %w[completed]))
        expect(json.count).to be > 0
        json.each { |e| expect(e["enrollment_state"]).to eql "completed" }
      end

      it "lists its own enrollments" do
        json = api_call(:get, @user_path, @user_params)
        enrollments = @user.enrollments.current.eager_load(:user).order("users.sortable_name ASC")
        expect(json).to eq(enrollments.map do |e|
          {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "id" => e.user.id,
              "login_id" => @user.pseudonym.unique_id,
              "created_at" => e.user.created_at.iso8601
            },
            "html_url" => course_user_url(e.course_id, e.user_id),
            "grades" => {
              "html_url" => course_student_grades_url(e.course_id, e.user_id),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
            },
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "last_activity_at" => nil,
            "last_attended_at" => nil,
            "total_activity_time" => 0
          }
        end)
      end

      context "override scores" do
        let(:student_grades) do
          json = api_call(:get, @user_path, @user_params)
          json.first.fetch("grades")
        end

        before(:once) do
          @enrollment.scores.create!(course_score: true, current_score: 67, override_score: 81)
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
        end

        context "when Final Grade Override is enabled and allowed" do
          it "sets current_score to the override score" do
            expect(student_grades.fetch("current_score")).to be 81.0
          end

          it "sets current_grade to the override grade" do
            expect(student_grades.fetch("current_grade")).to eq "B-"
          end
        end

        context "when Final Grade Override is not allowed" do
          before(:once) do
            @course.update!(allow_final_grade_override: false)
          end

          it "sets current_score to the computed score" do
            expect(student_grades.fetch("current_score")).to be 67.0
          end

          it "sets current_grade to the computed grade" do
            expect(student_grades.fetch("current_grade")).to eq "D+"
          end
        end

        context "when Final Grade Override is disabled" do
          before(:once) do
            @course.disable_feature!(:final_grades_override)
          end

          it "sets current_score to the computed score" do
            expect(student_grades.fetch("current_score")).to be 67.0
          end

          it "sets current_grade to the computed grade" do
            expect(student_grades.fetch("current_grade")).to eq "D+"
          end
        end
      end

      describe "current points" do
        let_once(:course) { Course.create! }
        let_once(:student) { User.create! }
        let_once(:teacher) { User.create! }

        let_once(:base_params) { { controller: "enrollments_api", action: "index", format: "json" } }

        before(:once) do
          course.offer!

          course.enroll_teacher(teacher, enrollment_state: "active")
          enrollment = course.enroll_student(student, enrollment_state: "active")
          enrollment.scores.create!(current_points: 75, unposted_current_points: 99)
        end

        context "for a user who can manage grades for the enrollment's course" do
          let_once(:api_path) { "/api/v1/courses/#{course.id}/enrollments" }
          let_once(:params_without_points) { base_params.merge({ course_id: course.id.to_param }) }

          context "when requesting current points" do
            let(:enrollment_grades_json) do
              params = params_without_points.merge({ include: ["current_points"] })
              json = api_call_as_user(teacher, :get, api_path, params)
              json.find { |enrollment| enrollment["user_id"] == student.id }["grades"]
            end

            it "includes the current_points field" do
              expect(enrollment_grades_json["current_points"]).to eq 75
            end

            it "includes the unposted_current_points field" do
              expect(enrollment_grades_json["unposted_current_points"]).to eq 99
            end
          end

          context "when not requesting current points" do
            let(:enrollment_grades_json) do
              json = api_call_as_user(teacher, :get, api_path, params_without_points)
              json.find { |enrollment| enrollment["user_id"] == student.id }["grades"]
            end

            it "does not include the current_points field" do
              expect(enrollment_grades_json).not_to include("current_points")
            end

            it "does not include the unposted_current_points field" do
              expect(enrollment_grades_json).not_to include("unposted_current_points")
            end
          end
        end

        context "for a student viewing their own enrollment" do
          let_once(:api_path) { "/api/v1/users/#{student.id}/enrollments" }
          let_once(:params_without_points) { base_params.merge({ user_id: student.id.to_param }) }

          context "when requesting current points" do
            let(:enrollment_grades_json) do
              params = params_without_points.merge({ include: ["current_points"] })
              json = api_call_as_user(student, :get, api_path, params)
              json.find { |enrollment| enrollment["user_id"] == student.id }["grades"]
            end

            it "includes the current_points field" do
              expect(enrollment_grades_json["current_points"]).to eq 75
            end

            it "does not include the unposted_current_points field" do
              expect(enrollment_grades_json).not_to include("unposted_current_points")
            end
          end

          context "when not requesting current points" do
            let(:enrollment_grades_json) do
              json = api_call_as_user(student, :get, api_path, params_without_points)
              json.find { |enrollment| enrollment["user_id"] == student.id }["grades"]
            end

            it "does not return the current_points field" do
              expect(enrollment_grades_json).not_to include("current_points")
            end

            it "does not return the unposted_current_points field" do
              expect(enrollment_grades_json).not_to include("unposted_current_points")
            end
          end
        end
      end

      it "does not display grades when hide_final_grades is true for the course" do
        @course.hide_final_grades = true
        @course.save

        json = api_call(:get, @user_path, @user_params)
        expect(json[0]["grades"].keys).to eql %w[html_url]
      end

      it "does not show enrollments for courses that aren't published" do
        course_factory
        @course.claim
        enrollment = course_factory.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, "active")

        # Request w/o a state[] filter.
        json = api_call(:get, @user_path, @user_params)
        expect(json.pluck("id")).not_to include enrollment.id

        # Request w/ a state[] filter.
        json = api_call(:get,
                        @user_path,
                        @user_params.merge(state: %w[active], type: %w[StudentEnrollment]))
        expect(json.pluck("id")).not_to include enrollment.id
      end

      it "shows enrollments for courses that aren't published if state[]=current_and_future" do
        course_factory
        @course.claim
        enrollment = @course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, "active")

        json = api_call(:get,
                        @user_path,
                        @user_params.merge(state: %w[current_and_future], type: %w[StudentEnrollment]))
        expect(json.pluck("id")).to include enrollment.id
      end

      it "shows enrollments for courses with future start dates if state[]=current_and_future" do
        course_factory
        @course.update(start_at: 1.week.from_now, restrict_enrollments_to_course_dates: true)
        enrollment = @course.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, "active")
        expect(enrollment.enrollment_state.state).to eq "pending_active"

        json = api_call(:get,
                        @user_path,
                        @user_params.merge(state: %w[current_and_future], type: %w[StudentEnrollment]))
        expect(json.pluck("id")).to include enrollment.id
      end

      it "accepts multiple state[] filters" do
        course_factory
        @course.offer!
        enrollment = course_factory.enroll_student(@user)
        enrollment.update_attribute(:workflow_state, "completed")

        json = api_call(:get,
                        @user_path,
                        @user_params.merge(state: %w[active completed]))
        expect(json.map { |e| e["id"].to_i }.sort).to eq @user.enrollments.map(&:id).sort
      end

      it "excludes invited enrollments in soft-concluded courses" do
        term = Account.default.enrollment_terms.create! end_at: 1.day.ago

        enrollment1 = course_with_student enrollment_state: :invited
        enrollment1.course.offer!
        enrollment1.course.enrollment_term = term
        enrollment1.course.save!

        enrollment2 = course_with_student enrollment_state: :invited, user: @student
        enrollment2.course.offer!

        json = api_call(:get, "/api/v1/users/self/enrollments", @user_params.merge(user_id: "self"))
        expect(json.pluck("id")).to match_array([enrollment2.id])
      end

      it "does not include the users' sis and login ids" do
        json = api_call(:get, @path, @params)
        json.each do |res|
          %w[sis_user_id login_id].each { |key| expect(res["user"]).not_to include(key) }
        end
      end
    end

    context "a teacher" do
      before do
        @user = @teacher
      end

      it "includes users' sis and login ids" do
        json = api_call(:get, @path, @params)
        enrollments = %w[observer student ta teacher].inject([]) do |res, type|
          res + @course.send(:"#{type}_enrollments").preload(:user)
        end
        enrollments = enrollments.sort_by { |e| [e.type, e.user.sortable_name] }
        expect(json).to eq(enrollments.map do |e|
          user_json = {
            "name" => e.user.name,
            "sortable_name" => e.user.sortable_name,
            "short_name" => e.user.short_name,
            "id" => e.user.id,
            "created_at" => e.user.created_at.iso8601,
            "login_id" => e.user.pseudonym ? e.user.pseudonym.unique_id : nil
          }
          user_json["sis_user_id"] = e.user.pseudonym.sis_user_id
          user_json["integration_id"] = e.user.pseudonym.integration_id
          h = {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "user" => user_json,
            "html_url" => course_user_url(@course, e.user),
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "last_activity_at" => nil,
            "last_attended_at" => nil,
            "total_activity_time" => 0,
            "course_integration_id" => nil,
            "sis_account_id" => nil,
            "sis_course_id" => nil,
            "sis_section_id" => nil,
            "sis_user_id" => nil,
            "section_integration_id" => nil
          }
          if e.student?
            h["grades"] = {
              "html_url" => course_student_grades_url(@course, e.user),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
              "unposted_current_score" => nil,
              "unposted_current_grade" => nil,
              "unposted_final_score" => nil,
              "unposted_final_grade" => nil
            }
          end
          h
        end)
      end

      context "override scores" do
        let(:student_grades) do
          json = api_call(:get, @path, @params)
          json.detect { |enrollment| enrollment.fetch("id") == @enrollment.id }.fetch("grades")
        end

        before(:once) do
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
          @enrollment.scores.create!(course_score: true, current_score: 67, override_score: 81)
        end

        context "when Final Grade Override is enabled and allowed" do
          it "includes the override score" do
            expect(student_grades.fetch("override_score")).to be 81.0
          end

          it "includes the override grade" do
            expect(student_grades.fetch("override_grade")).to eq "B-"
          end

          it "continues to include the original score as current_score" do
            expect(student_grades.fetch("current_score")).to be 67.0
          end

          it "continues to include the original grade as current_grade" do
            expect(student_grades.fetch("current_grade")).to eq "D+"
          end

          it "excludes the override score when no override exists" do
            @enrollment.scores.each(&:destroy!)
            expect(student_grades).not_to have_key("override_score")
          end

          it "excludes the override grade when no override exists" do
            @enrollment.scores.each(&:destroy!)
            expect(student_grades).not_to have_key("override_grade")
          end
        end

        context "when Final Grade Override is not allowed" do
          before(:once) do
            @course.update!(allow_final_grade_override: false)
          end

          it "excludes the override score" do
            expect(student_grades).not_to have_key("override_score")
          end

          it "excludes the override grade" do
            expect(student_grades).not_to have_key("override_grade")
          end
        end

        context "when Final Grade Override is disabled" do
          before(:once) do
            @course.disable_feature!(:final_grades_override)
          end

          it "excludes the override score" do
            expect(student_grades).not_to have_key("override_score")
          end

          it "excludes the override grade" do
            expect(student_grades).not_to have_key("override_grade")
          end
        end
      end
    end

    context "as an observer in a course" do
      let(:course) { Course.create! }
      let(:observed_student) { User.create! }
      let(:hidden_student) { User.create! }
      let(:observer) { User.create! }

      let(:request_params) do
        {
          action: "index",
          controller: "enrollments_api",
          course_id: course.id,
          format: :json
        }
      end

      let(:enrollment_json) do
        api_call_as_user(observer, :get, "/api/v1/courses/#{course.id}/enrollments", request_params)
      end

      let(:student_enrollments) do
        enrollment_json.select { |enrollment| enrollment["type"] == "StudentEnrollment" }
      end

      let(:observer_enrollments) do
        enrollment_json.select { |enrollment| enrollment["type"] == "ObserverEnrollment" }
      end

      before do
        course.enroll_student(observed_student, active_all: true)
        course.enroll_student(hidden_student, active_all: true)

        observer.register!
        # add an observer, but don't link them to any students yet
        course.enroll_user(observer, "ObserverEnrollment")
        user_session(observer)
      end

      context "when the observer is observing at least one student in the course" do
        before do
          course.enroll_user(observer, "ObserverEnrollment", associated_user_id: observed_student.id)
        end

        it "returns a successful response" do
          api_call_as_user(observer, :get, "/api/v1/courses/#{course.id}/enrollments", request_params)
          expect(response).to have_http_status :ok
        end

        it "includes active enrollments for each observed student" do
          expect(student_enrollments.pluck("user_id")).to contain_exactly(observed_student.id)
        end

        it "includes both the observer's base enrollment and enrollments associated with observees" do
          expect(observer_enrollments.pluck("user_id", "associated_user_id")).to match_array([
                                                                                               [observer.id, nil],
                                                                                               [observer.id, observed_student.id]
                                                                                             ])
        end

        it "does not include enrollments for students the user is not observing" do
          expect(student_enrollments.pluck("user_id")).not_to include(hidden_student.id)
        end

        it "does not include students who were once observed but no longer are" do
          observer.observer_enrollments.find_by(associated_user_id: observed_student.id).destroy
          aggregate_failures do
            expect(student_enrollments).to be_empty
            expect(observer_enrollments.length).to eq 1
            expect(observer_enrollments.first["associated_user_id"]).to be_nil
          end
        end

        it "returns unauthorized if the user has no non-deleted observer enrollments" do
          observer.observer_enrollments.destroy_all
          api_call_as_user(observer, :get, "/api/v1/courses/#{course.id}/enrollments", request_params)
          expect(response).to have_http_status :unauthorized
        end
      end

      context "when the observer is requesting enrollments for a specific user in a course" do
        before do
          course.enroll_user(observer, "ObserverEnrollment", associated_user_id: observed_student.id)
        end

        it "returns a successful response" do
          request_params[:user_id] = observed_student.id
          api_call_as_user(observer, :get, "/api/v1/courses/#{course.id}/enrollments", request_params)
          expect(response).to have_http_status :ok
        end
      end

      it "returns only the base ObserverEnrollment if the observer has not been linked to any students" do
        aggregate_failures do
          expect(enrollment_json.length).to eq 1
          expect(enrollment_json.first["user_id"]).to be observer.id
          expect(enrollment_json.first["associated_user_id"]).to be_nil
        end
      end
    end

    context "a user without permissions" do
      before :once do
        @user = user_with_pseudonym(name: "Don Draper", username: "ddraper@sterling-cooper.com")
      end

      it "returns 401 unauthorized for a course listing" do
        raw_api_call(:get, "/api/v1/courses/#{@course.id}/enrollments", @params.merge(course_id: @course.id.to_param))
        expect(response).to have_http_status :unauthorized
      end

      it "returns 401 unauthorized for a user listing" do
        raw_api_call(:get, @user_path, @user_params)
        expect(response).to have_http_status :unauthorized
      end

      it "returns 401 unauthorized for a user requesting an enrollment object by id" do
        raw_api_call(:get, "#{@enroll_path}/#{@enrollment.id}", @enroll_params)
        expect(response).to have_http_status :unauthorized
      end

      it "returns 401 unauthorized for a course listing with a specific user_if provided" do
        raw_api_call(:get, @path, @params.merge(user_id: @course.students.active.first.id))
        expect(response).to have_http_status :unauthorized
      end

      it "returns 404 for a user querying from the wrong account" do
        sub = @enrollment.root_account.sub_accounts.create!(name: "sub")
        bad_path = "/api/v1/accounts/#{sub.id}/enrollments/#{@enrollment.id}"
        enroll_params = {
          controller: "enrollments_api",
          action: "show",
          account_id: sub.id,
          id: @enrollment.id,
          format: "json"
        }
        raw_api_call(:get, bad_path, enroll_params)
        expect(response).to have_http_status :not_found
      end
    end

    context "a parent observer using parent app" do
      before :once do
        @student = user_factory(active_all: true, active_state: "active")
        3.times do
          course_factory
          @course.enroll_student(@student, enrollment_state: "active")
        end
        @observer = user_factory(active_all: true, active_state: "active")
        add_linked_observer(@student, @observer)
        @user = @observer
        @user_path = "/api/v1/users/#{@student.id}/enrollments"
        @user_params = { controller: "enrollments_api", action: "index", user_id: @student.id.to_param, format: "json" }
      end

      it "shows all enrollments for the observee (student)" do
        json = api_call(:get, @user_path, @user_params)
        expect(json.length).to be 3
      end

      it "does not authorize the parent to see other students' enrollments" do
        @other_student = user_factory(active_all: true, active_state: "active")
        @user = @observer
        path = "/api/v1/users/#{@other_student.id}/enrollments"
        params = { controller: "enrollments_api", action: "index", user_id: @other_student.id.to_param, format: "json" }
        raw_api_call(:get, path, params)
        expect(response).to have_http_status :unauthorized
      end
    end

    describe "sharding" do
      specs_require_sharding

      context "when not scoped by a user" do
        it "returns enrollments from the course's shard" do
          @shard1.activate { @user = user_factory(active_user: true) }

          account_admin_user(account: @course.account, user: @user)

          json = api_call(:get, @path, @params)

          enrollment_ids = json.pluck("id")
          expect(enrollment_ids.sort).to eq(@course.enrollments.map(&:id).sort)
          expect(json.length).to eq 2
        end

        it "returns enrollments from the course's shard for an observer user" do
          @shard1.activate do
            @enrolled_user = user_factory(active_user: true)

            account = Account.create!
            @cs_course = Course.create!(account:)
            @cs_course.enroll_user(@user, "ObserverEnrollment", enrollment_state: "active")
            @cs_course.enroll_user(@enrolled_user, "StudentEnrollment", enrollment_state: "active")
          end

          @params[:course_id] = @cs_course.id
          json = api_call(:get, "/api/v1/courses/#{@cs_course.id}/enrollments", @params)

          enrollment_ids = json.pluck("id")
          expect(enrollment_ids.sort).to eq(@cs_course.enrollments.map(&:id).sort)
          expect(json.length).to eq 2
        end
      end

      context "when scoped by a user" do
        it "returns enrollments from all of the current user's associated shards" do
          # create a user on a different shard
          @shard1.activate { @user = User.create!(name: "outofshard") }

          @course.enroll_student(@user)

          # query own enrollment(s) as the out-of-shard user
          @path = "#{@path}?user_id=self"
          @params[:user_id] = "self"

          json = api_call(:get, @path, @params)

          expect(json.length).to eq 1
          expect(json.first["course_id"]).to eq(@course.id)
          expect(json.first["user_id"]).to eq(@user.global_id)
        end

        it "returns enrollments from all of another user's associated shards" do
          @shard1.activate { @other_course = Course.create! account: Account.create! }
          @course.enroll_student(@user, enrollment_state: "active")
          @other_course.enroll_student(@user, enrollment_state: "active")
          @student = @user
          @observer = user_factory
          add_linked_observer(@student, @observer)
          json = api_call_as_user(@observer,
                                  :get,
                                  "/api/v1/users/#{@student.id}/enrollments",
                                  { controller: "enrollments_api",
                                    action: "index",
                                    user_id: @student.to_param,
                                    format: "json" })
          courses = json.pluck("course_id")
          expect(courses).to include @course.id
          expect(courses).to include @other_course.id
        end
      end
    end

    describe "pagination" do
      shared_examples_for "numeric pagination" do
        it "properly paginates" do
          json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(page: 1.to_param, per_page: 1.to_param))
          enrollments = %w[observer student ta teacher].inject([]) do |res, type|
            res + @course.send(:"#{type}_enrollments").preload(:user)
          end.map do |e|
            h = {
              "root_account_id" => e.root_account_id,
              "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
              "enrollment_state" => e.workflow_state,
              "id" => e.id,
              "user_id" => e.user_id,
              "type" => e.type,
              "role" => e.role.name,
              "role_id" => e.role.id,
              "course_section_id" => e.course_section_id,
              "course_id" => e.course_id,
              "user" => {
                "name" => e.user.name,
                "sortable_name" => e.user.sortable_name,
                "short_name" => e.user.short_name,
                "id" => e.user.id,
                "created_at" => e.user.created_at.iso8601
              },
              "html_url" => course_user_url(@course, e.user),
              "associated_user_id" => nil,
              "updated_at" => e.updated_at.xmlschema,
              "created_at" => e.created_at.xmlschema,
              "start_at" => nil,
              "end_at" => nil,
            }
            if e.student?
              h["grades"] = {
                "html_url" => course_student_grades_url(@course, e.user),
                "final_score" => nil,
                "current_score" => nil,
                "final_grade" => nil,
                "current_grade" => nil,
              }
            end
            if e.user == @user
              h.merge!(
                "last_activity_at" => nil,
                "last_attended_at" => nil,
                "total_activity_time" => 0
              )
            end
            h
          end

          link_header = response.headers["Link"].split(",")
          expect(link_header[0]).to match(/page=1&per_page=1/) # current page
          expect(link_header[1]).to match(/page=2&per_page=1/) # next page
          expect(link_header[2]).to match(/page=1&per_page=1/) # first page
          expect(link_header[3]).to match(/page=2&per_page=1/) # last page
          expect(json).to eql [enrollments[0]]

          json = api_call(:get, "#{@path}?page=2&per_page=1", @params.merge(page: 2.to_param, per_page: 1.to_param))
          link_header = response.headers["Link"].split(",")
          expect(link_header[0]).to match(/page=2&per_page=1/) # current page
          expect(link_header[1]).to match(/page=1&per_page=1/) # prev page
          expect(link_header[2]).to match(/page=1&per_page=1/) # first page
          expect(link_header[3]).to match(/page=2&per_page=1/) # last page
          expect(json).to eql [enrollments[1]]
        end
      end

      shared_examples_for "bookmarked pagination" do
        it "properly paginates" do
          json = api_call(:get, "#{@path}?page=1&per_page=1", @params.merge(page: 1.to_param, per_page: 1.to_param))
          enrollments = %w[observer student ta teacher].inject([]) do |res, type|
            res + @course.send(:"#{type}_enrollments").preload(:user)
          end.map do |e|
            h = {
              "root_account_id" => e.root_account_id,
              "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
              "enrollment_state" => e.workflow_state,
              "id" => e.id,
              "user_id" => e.user_id,
              "type" => e.type,
              "role" => e.role.name,
              "role_id" => e.role.id,
              "course_section_id" => e.course_section_id,
              "course_id" => e.course_id,
              "user" => {
                "name" => e.user.name,
                "sortable_name" => e.user.sortable_name,
                "short_name" => e.user.short_name,
                "id" => e.user.id,
                "created_at" => e.user.created_at.iso8601
              },
              "html_url" => course_user_url(@course, e.user),
              "associated_user_id" => nil,
              "updated_at" => e.updated_at.xmlschema,
              "created_at" => e.created_at.xmlschema,
              "start_at" => nil,
              "end_at" => nil,
            }
            if e.student?
              h["grades"] = {
                "html_url" => course_student_grades_url(@course, e.user),
                "final_score" => nil,
                "current_score" => nil,
                "final_grade" => nil,
                "current_grade" => nil,
              }
            end
            if e.user == @user
              h.merge!(
                "last_activity_at" => nil,
                "last_attended_at" => nil,
                "total_activity_time" => 0
              )
            end
            h
          end
          link_header = response.headers["Link"].split(",")
          expect(link_header[0]).to match(/page=.*&per_page=1/) # current page
          md = link_header[1].match(/page=(.*)&per_page=1/) # next page
          bookmark = md[1]
          expect(bookmark).to be_present
          expect(link_header[2]).to match(/page=.*&per_page=1/) # first page
          expect(json).to eql [enrollments[0]]

          json = api_call(:get, "#{@path}?page=#{bookmark}&per_page=1", @params.merge(page: bookmark, per_page: 1.to_param))
          link_header = response.headers["Link"].split(",")
          expect(link_header[0]).to match(/page=#{bookmark}&per_page=1/) # current page
          expect(link_header[1]).to match(/page=.*&per_page=1/) # first page
          expect(link_header[2]).to match(/page=.*&per_page=1/) # last page
          expect(json).to eql [enrollments[1]]
        end
      end

      context "with normal settings" do
        it_behaves_like "bookmarked pagination"

        context "with developer key pagination override" do
          before do
            global_id = Shard.global_id_for(DeveloperKey.default.id)
            Setting.set("pagination_override_key_list", global_id.to_s)
          end

          it_behaves_like "numeric pagination"
        end
      end
    end

    context "inactive enrollments" do
      before do
        @inactive_user = user_with_pseudonym(name: "Inactive User")
        student_in_course(course: @course, user: @inactive_user)
        @inactive_enroll = @inactive_user.enrollments.first
        @inactive_enroll.deactivate
      end

      it "excludes users with inactive enrollments for students" do
        student_in_course(course: @course, active_all: true, user: user_with_pseudonym)
        json = api_call(:get, @path, @params)
        expect(json.pluck("id")).not_to include(@inactive_enroll.id)
      end

      it "includes users with inactive enrollments for teachers" do
        teacher_in_course(course: @course, active_all: true, user: user_with_pseudonym)
        json = api_call(:get, @path, @params)
        expect(json.pluck("id")).to include(@inactive_enroll.id)
        enroll_json = json.detect { |e| e["id"] == @inactive_enroll.id }
        expect(enroll_json["user_id"]).to eq @inactive_user.id
        expect(enroll_json["enrollment_state"]).to eq "inactive"
      end
    end

    describe "enrollment deletion, conclusion and inactivation" do
      before :once do
        course_with_student(active_all: true, user: user_with_pseudonym)
        @enrollment = @student.enrollments.first

        @teacher = User.create!(name: "Test Teacher")
        @teacher.pseudonyms.create!(unique_id: "test+teacher@example.com")
        @course.enroll_teacher(@teacher)
        @user = @teacher

        @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}"
        @params = { controller: "enrollments_api",
                    action: "destroy",
                    course_id: @course.id.to_param,
                    id: @enrollment.id.to_param,
                    format: "json" }
      end

      before do
        time = Time.now
        allow(Time).to receive(:now).and_return(time)
      end

      context "an authorized user" do
        it "is able to conclude an enrollment" do
          json = api_call(:delete, "#{@path}?task=conclude", @params.merge(task: "conclude"))
          @enrollment.reload
          expect(json).to eq({
                               "root_account_id" => @enrollment.root_account_id,
                               "id" => @enrollment.id,
                               "user_id" => @student.id,
                               "course_section_id" => @enrollment.course_section_id,
                               "limit_privileges_to_course_section" => @enrollment.limit_privileges_to_course_section,
                               "enrollment_state" => "completed",
                               "course_id" => @course.id,
                               "type" => @enrollment.type,
                               "role" => @enrollment.role.name,
                               "role_id" => @enrollment.role.id,
                               "html_url" => course_user_url(@course, @student),
                               "grades" => {
                                 "html_url" => course_student_grades_url(@course, @student),
                                 "final_score" => nil,
                                 "current_score" => nil,
                                 "final_grade" => nil,
                                 "current_grade" => nil,
                                 "unposted_current_score" => nil,
                                 "unposted_current_grade" => nil,
                                 "unposted_final_score" => nil,
                                 "unposted_final_grade" => nil
                               },
                               "associated_user_id" => @enrollment.associated_user_id,
                               "updated_at" => @enrollment.updated_at.xmlschema,
                               "created_at" => @enrollment.created_at.xmlschema,
                               "start_at" => nil,
                               "end_at" => nil,
                               "last_activity_at" => nil,
                               "last_attended_at" => nil,
                               "total_activity_time" => 0,
                               "course_integration_id" => nil,
                               "sis_account_id" => nil,
                               "sis_course_id" => nil,
                               "sis_section_id" => nil,
                               "sis_user_id" => nil,
                               "section_integration_id" => nil
                             })
        end

        it "is not able to delete an enrollment for other courses" do
          @account = Account.default
          @sub_account = Account.create(parent_account: @account, name: "English")
          @sub_account.save!
          @user = user_with_pseudonym(username: "sub_admin@example.com")
          @sub_account.account_users.create!(user: @user)
          @course = @sub_account.courses.create(name: "sub")
          @course.account_id = @sub_account.id
          @course.save!

          @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}"
          @params = { controller: "enrollments_api",
                      action: "destroy",
                      course_id: @course.id.to_param,
                      id: @enrollment.id.to_param,
                      format: "json" }

          raw_api_call(:delete, "#{@path}?task=delete", @params.merge(task: "delete"))
          expect(response).to have_http_status :not_found
          expect(JSON.parse(response.body)["errors"]).to eq [{ "message" => "The specified resource does not exist." }]
        end

        it "is able to delete an enrollment" do
          json = api_call(:delete, "#{@path}?task=delete", @params.merge(task: "delete"))
          @enrollment.reload
          expect(json).to eq({
                               "root_account_id" => @enrollment.root_account_id,
                               "id" => @enrollment.id,
                               "user_id" => @student.id,
                               "course_section_id" => @enrollment.course_section_id,
                               "limit_privileges_to_course_section" => @enrollment.limit_privileges_to_course_section,
                               "enrollment_state" => "deleted",
                               "course_id" => @course.id,
                               "type" => @enrollment.type,
                               "role" => @enrollment.role.name,
                               "role_id" => @enrollment.role.id,
                               "html_url" => course_user_url(@course, @student),
                               "grades" => {
                                 "html_url" => course_student_grades_url(@course, @student),
                                 "final_score" => nil,
                                 "current_score" => nil,
                                 "final_grade" => nil,
                                 "current_grade" => nil,
                                 "unposted_current_score" => nil,
                                 "unposted_current_grade" => nil,
                                 "unposted_final_score" => nil,
                                 "unposted_final_grade" => nil
                               },
                               "associated_user_id" => @enrollment.associated_user_id,
                               "updated_at" => @enrollment.updated_at.xmlschema,
                               "created_at" => @enrollment.created_at.xmlschema,
                               "start_at" => nil,
                               "end_at" => nil,
                               "last_activity_at" => nil,
                               "last_attended_at" => nil,
                               "total_activity_time" => 0,
                               "course_integration_id" => nil,
                               "sis_account_id" => nil,
                               "sis_course_id" => nil,
                               "sis_section_id" => nil,
                               "sis_user_id" => nil,
                               "section_integration_id" => nil
                             })
        end

        it "is not able to unenroll itself if it can't re-enroll itself" do
          enrollment = @teacher.enrollments.first

          @path.sub!(@enrollment.id.to_s, enrollment.id.to_s)
          @params[:id] = enrollment.id.to_param
          @params[:task] = "delete"

          raw_api_call(:delete, "#{@path}?task=delete", @params)

          expect(response).to have_http_status :unauthorized
          expect(JSON.parse(response.body)).to eq({
                                                    "errors" => [{ "message" => "user not authorized to perform that action" }],
                                                    "status" => "unauthorized"
                                                  })
        end

        it "is able to deactivate an enrollment using the 'inactivate' task" do
          json = api_call(:delete, "#{@path}?task=inactivate", @params.merge(task: "inactivate"))
          expect(json["enrollment_state"]).to eq "inactive"
          @enrollment.reload
          expect(@enrollment.workflow_state).to eq "inactive"
        end

        it "is able to deactivate an enrollment using the 'deactivate' task" do
          json = api_call(:delete, "#{@path}?task=deactivate", @params.merge(task: "deactivate"))
          expect(json["enrollment_state"]).to eq "inactive"
          @enrollment.reload
          expect(@enrollment.workflow_state).to eq "inactive"
        end
      end

      context "an unauthorized user" do
        it "returns 401" do
          @user = @student
          raw_api_call(:delete, @path, @params)
          expect(response).to have_http_status :unauthorized

          raw_api_call(:delete, "#{@path}?task=delete", @params.merge(task: "delete"))
          expect(response).to have_http_status :unauthorized

          raw_api_call(:delete, "#{@path}?task=inactivate", @params.merge(task: "inactivate"))
          expect(response).to have_http_status :unauthorized

          raw_api_call(:delete, "#{@path}?task=deactivate", @params.merge(task: "deactivate"))
          expect(response).to have_http_status :unauthorized
        end
      end
    end

    describe "enrollment reactivation" do
      before :once do
        course_with_student(active_all: true, user: user_with_pseudonym)
        teacher_in_course(course: @course, user: user_with_pseudonym)
        @enrollment = @student.enrollments.first
        @enrollment.deactivate

        @path = "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reactivate"
        @params = { controller: "enrollments_api",
                    action: "reactivate",
                    course_id: @course.id.to_param,
                    id: @enrollment.id.to_param,
                    format: "json" }
      end

      it "requires authorization" do
        @user = @student
        raw_api_call(:put, @path, @params)
        expect(response).to have_http_status :unauthorized
      end

      it "is able to reactivate an enrollment" do
        json = api_call(:put, @path, @params)
        expect(json["enrollment_state"]).to eq "active"
        @enrollment.reload
        expect(@enrollment.workflow_state).to eq "active"
      end
    end

    describe "show" do
      before(:once) do
        @account = Account.default
        account_admin_user(account: @account)
        student_in_course active_all: true
        @base_path = "/api/v1/accounts/#{@account.id}/enrollments"
        @params = { controller: "enrollments_api",
                    action: "show",
                    account_id: @account.to_param,
                    format: "json" }
      end

      context "admin" do
        before(:once) do
          @user = @admin
        end

        it "shows other's enrollment" do
          json = api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param))
          expect(json["id"]).to eql(@enrollment.id)
        end
      end

      context "student" do
        before(:once) do
          @user = @student
        end

        it "shows own enrollment" do
          json = api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param))
          expect(json["id"]).to eql(@enrollment.id)
        end

        it "does not show other's enrollment" do
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

        it "does not show enrollment" do
          api_call(:get, @base_path + "/#{@enrollment.id}", @params.merge(id: @enrollment.to_param), {}, {}, { expected_status: 401 })
        end
      end
    end

    describe "filters" do
      it "properly filters by a single enrollment type" do
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment", @params.merge(type: %w[StudentEnrollment]))
        expect(json).to eql(@course.student_enrollments.map do |e|
          {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "html_url" => course_user_url(@course, e.user),
            "grades" => {
              "html_url" => course_student_grades_url(@course, e.user),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
            },
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "last_activity_at" => nil,
            "last_attended_at" => nil,
            "total_activity_time" => 0,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "id" => e.user.id,
              "created_at" => e.user.created_at.iso8601
            }
          }
        end)
      end

      it "400s when a bad role name is passed" do
        api_call(:get, "#{@path}?role[]=garbage", @params.merge(role: %w[garbage]))
        expect(response).to have_http_status :bad_request
      end

      it "properly filters by multiple enrollment types" do
        # set up some enrollments that shouldn't be returned by the api
        request_user = @user
        @new_user = user_with_pseudonym(name: "Zombo", username: "nobody2@example.com")
        @course.enroll_user(@new_user, "TaEnrollment", enrollment_state: "active")
        @course.enroll_user(@new_user, "ObserverEnrollment", enrollment_state: "active")
        @user = request_user
        json = api_call(:get, "#{@path}?type[]=StudentEnrollment&type[]=TeacherEnrollment", @params.merge(type: %w[StudentEnrollment TeacherEnrollment]))
        enrollments = (@course.student_enrollments + @course.teacher_enrollments).sort_by { |e| [e.type, e.user.sortable_name] }

        expect(json).to eq(enrollments.map do |e|
          h = {
            "root_account_id" => e.root_account_id,
            "limit_privileges_to_course_section" => e.limit_privileges_to_course_section,
            "enrollment_state" => e.workflow_state,
            "id" => e.id,
            "user_id" => e.user_id,
            "type" => e.type,
            "role" => e.role.name,
            "role_id" => e.role.id,
            "course_section_id" => e.course_section_id,
            "course_id" => e.course_id,
            "html_url" => course_user_url(@course, e.user),
            "associated_user_id" => nil,
            "updated_at" => e.updated_at.xmlschema,
            "created_at" => e.created_at.xmlschema,
            "start_at" => nil,
            "end_at" => nil,
            "user" => {
              "name" => e.user.name,
              "sortable_name" => e.user.sortable_name,
              "short_name" => e.user.short_name,
              "id" => e.user.id,
              "created_at" => e.user.created_at.iso8601
            }
          }
          if e.student?
            h["grades"] = {
              "html_url" => course_student_grades_url(@course, e.user),
              "final_score" => nil,
              "current_score" => nil,
              "final_grade" => nil,
              "current_grade" => nil,
            }
          end
          if e.user == @user
            h.merge!(
              "last_activity_at" => nil,
              "last_attended_at" => nil,
              "total_activity_time" => 0
            )
          end
          h
        end)
      end

      it "returns an empty array when no user enrollments match a filter" do
        site_admin_user(active_all: true)

        json = api_call(:get,
                        "#{@user_path}?type[]=TeacherEnrollment",
                        @user_params.merge(type: %w[TeacherEnrollment]))

        expect(json).to be_empty
      end
    end
  end

  describe "enrollment invitations" do
    it "accepts invitation" do
      course_with_student_logged_in(active_course: true, active_user: true)

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(@enrollment.reload).to be_active
    end

    it "accepts one invitation when there are multiple sections" do
      course = course_factory({ active_course: true })
      s1 = course.course_sections.create
      s2 = course.course_sections.create
      en1 = course_with_student(active_user: true, course:, section: s1, enrollment_state: "invited")
      en2 = course_with_student(course:, section: s2, enrollment_state: "invited", allow_multiple_enrollments: true, user: @student)

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{en1.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: en1.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(en1.reload.workflow_state).to eq "active"
      expect(en2.reload.workflow_state).to eq "invited"

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{en2.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: en2.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(en2.reload.workflow_state).to eq "active"
    end

    it "rejects invitation" do
      course_with_student_logged_in(active_course: true, active_user: true)

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reject",
                              { controller: "enrollments_api",
                                action: "reject",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(@enrollment.reload.workflow_state).to eq "rejected"
    end

    it "rejects and then accept" do
      course_with_student_logged_in(active_course: true, active_user: true)

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reject",
                              { controller: "enrollments_api",
                                action: "reject",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(@enrollment.reload.workflow_state).to eq "rejected"

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(json["success"]).to be true
      expect(@enrollment.reload.workflow_state).to eq "active"
    end

    it "does not accept after course has ended" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @course.soft_conclude!
      @course.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "no current invitation"
    end

    it "does not reject after course has ended" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @course.soft_conclude!
      @course.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reject",
                              { controller: "enrollments_api",
                                action: "reject",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "no current invitation"
    end

    it "does not accept if self_enrolled" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @enrollment.self_enrolled = true
      @enrollment.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "self enroll"
    end

    it "does not reject if self_enrolled" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @enrollment.self_enrolled = true
      @enrollment.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reject",
                              { controller: "enrollments_api",
                                action: "reject",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "self enroll"
    end

    it "does not accept if inactive" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @enrollment.workflow_state = "inactive"
      @enrollment.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/accept",
                              { controller: "enrollments_api",
                                action: "accept",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "membership not activated"
    end

    it "does not reject if inactive" do
      course_with_student_logged_in(active_course: true, active_user: true)
      @enrollment.workflow_state = "inactive"
      @enrollment.save

      json = api_call_as_user(@student,
                              :post,
                              "/api/v1/courses/#{@course.id}/enrollments/#{@enrollment.id}/reject",
                              { controller: "enrollments_api",
                                action: "reject",
                                course_id: @course.to_param,
                                id: @enrollment.to_param,
                                format: :json })
      expect(response).to have_http_status :bad_request
      expect(json["error"]).to eq "membership not activated"
    end
  end

  describe "#show_temporary_enrollment_status" do
    let_once(:start_at) { 1.day.ago }
    let_once(:end_at) { 1.day.from_now }

    before(:once) do
      Account.default.enable_feature!(:temporary_enrollments)
      @provider = user_factory(active_all: true)
      @recipient = user_factory(active_all: true)
      course1 = course_with_teacher(active_all: true, user: @provider).course
      course2 = course_with_teacher(active_all: true, user: @provider).course
      temporary_enrollment_pairing = TemporaryEnrollmentPairing.create!(root_account: Account.default, created_by: account_admin_user)
      course1.enroll_user(
        @recipient,
        "TeacherEnrollment",
        {
          role: teacher_role,
          temporary_enrollment_source_user_id: @provider.id,
          temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
          start_at:,
          end_at:
        }
      )
      course2.enroll_user(
        @recipient,
        "TeacherEnrollment",
        {
          role: teacher_role,
          temporary_enrollment_source_user_id: @provider.id,
          temporary_enrollment_pairing_id: temporary_enrollment_pairing.id,
          start_at:,
          end_at:
        }
      )
    end

    it "returns appropriate status for a provider" do
      user_path = "/api/v1/users/#{@provider.id}/temporary_enrollment_status"
      user_params = { controller: "enrollments_api",
                      action: "show_temporary_enrollment_status",
                      user_id: @provider.id,
                      format: "json" }
      json = api_call_as_user(account_admin_user, :get, user_path, user_params)
      expect(json.length).to eq(2)
      expect(json["is_provider"]).to be_truthy
      expect(json["is_recipient"]).to be_falsey
    end

    it "returns appropriate status for a recipient" do
      user_path = "/api/v1/users/#{@recipient.id}/temporary_enrollment_status"
      user_params = { controller: "enrollments_api",
                      action: "show_temporary_enrollment_status",
                      user_id: @recipient.id,
                      format: "json" }
      json = api_call_as_user(account_admin_user, :get, user_path, user_params)
      expect(json.length).to eq(2)
      expect(json["is_provider"]).to be_falsey
      expect(json["is_recipient"]).to be_truthy
    end
  end
end
