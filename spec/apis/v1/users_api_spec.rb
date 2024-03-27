# frozen_string_literal: true

#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
require_relative "../file_uploads_spec_helper"
require_relative "../../cassandra_spec_helper"

class TestUserApi
  include Api::V1::User
  attr_accessor :services_enabled, :context, :current_user, :params, :request

  def service_enabled?(service)
    @services_enabled.include? service
  end

  def avatar_image_url(*args)
    "avatar_image_url(#{args.first})"
  end

  def course_student_grades_url(_course_id, _user_id)
    ""
  end

  def course_user_url(_course_id, _user_id)
    ""
  end

  def initialize
    @domain_root_account = Account.default
    @params = {}
    @request = OpenStruct.new
  end
end

describe Api::V1::User do
  before :once do
    @admin = account_admin_user
    course_with_student(user: user_with_pseudonym(name: "Sheldon Cooper", username: "pvuser@example.com"))
    @student = @user
    @student.pseudonym.update_attribute(:sis_user_id, "sis-user-id")
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(user: @user)
  end

  before do
    @test_api = TestUserApi.new
    @test_api.services_enabled = []
    @test_api.request.protocol = "http"
  end

  context "user_json" do
    it "supports optionally including first_name" do
      json = @test_api.user_json(@student, @admin, {}, ["first_name"], @course)
      expect(json["first_name"]).to eq @student.first_name
    end

    it "supports optionally including last_name" do
      json = @test_api.user_json(@student, @admin, {}, ["last_name"], @course)
      expect(json["last_name"]).to eq @student.last_name
    end

    it "supports optionally providing the avatar if avatars are enabled" do
      @student.account.set_service_availability(:avatars, false)
      @student.account.save!
      expect(@test_api.user_json(@student, @admin, {}, ["avatar_url"], @course)).not_to have_key("avatar_url")
      @student.account.set_service_availability(:avatars, true)
      @student.account.save!
      expect(@test_api.user_json(@student, @admin, {}, [], @course)).not_to have_key("avatar_url")
      expect(@test_api.user_json(@student, @admin, {}, ["avatar_url"], @course)["avatar_url"]).to match("h:/images/messages/avatar-50.png")
    end

    it "only loads pseudonyms for the user once, even if there are multiple enrollments" do
      sis_stub = SisPseudonym.for(@student, @course, type: :trusted)
      expect(SisPseudonym).to receive(:for).once.and_return(sis_stub)
      ta_enrollment = ta_in_course(user: @student, course: @course)
      teacher_enrollment = teacher_in_course(user: @student, course: @course)
      @test_api.current_user = @admin
      @test_api.user_json(@student, @admin, {}, [], @course, [ta_enrollment, teacher_enrollment])
    end

    it "supports optionally including group_ids" do
      @group = @course.groups.create!(name: "My Group")
      @group.add_user(@student, "accepted", true)
      expect(@test_api.user_json(@student, @admin, {}, [], @course)).not_to have_key("group_ids")
      expect(@test_api.user_json(@student, @admin, {}, ["group_ids"], @course)["group_ids"]).to eq([@group.id])
    end

    it "uses the correct SIS pseudonym" do
      @user = User.create!(name: "User")
      @account2 = Account.create!
      @user.pseudonyms.create!(unique_id: "abc", account: @account2) { |p| p.sis_user_id = "abc" }
      @user.pseudonyms.create!(unique_id: "xyz", account: Account.default) { |p| p.sis_user_id = "xyz" }
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
                                                                                  "name" => "User",
                                                                                  "sortable_name" => "User",
                                                                                  "sis_import_id" => nil,
                                                                                  "id" => @user.id,
                                                                                  "created_at" => @user.created_at.iso8601,
                                                                                  "short_name" => "User",
                                                                                  "sis_user_id" => "xyz",
                                                                                  "integration_id" => nil,
                                                                                  "login_id" => "xyz"
                                                                                })
    end

    it "only tries to search on in region shards" do
      @user = User.create!(name: "User")
      expect(@user).to receive(:in_region_associated_shards).and_call_original
      @test_api.user_json(@user, @admin, {}, [], Account.default)
    end

    it "shows SIS data to sub account admins" do
      student = User.create!(name: "User")
      student.pseudonyms.create!(unique_id: "xyz", account: Account.default) { |p| p.sis_user_id = "xyz" }

      sub_account = Account.create!(parent_account: Account.default)
      sub_admin = account_admin_user(account: sub_account)

      course = sub_account.courses.create!

      expect(@test_api.user_json(student, sub_admin, {}, [], course)).to eq({
                                                                              "name" => "User",
                                                                              "sortable_name" => "User",
                                                                              "id" => student.id,
                                                                              "created_at" => student.created_at.iso8601,
                                                                              "short_name" => "User",
                                                                              "sis_user_id" => "xyz",
                                                                              "integration_id" => nil,
                                                                              "login_id" => "xyz"
                                                                            })
    end

    it "shows SIS data to teachers only in courses they are teachers in" do
      student = User.create!(name: "User")
      student.pseudonyms.create!(unique_id: "xyz", account: Account.default) { |p| p.sis_user_id = "xyz" }

      teacher = user_factory
      course1 = course_factory(active_all: true)
      course1.enroll_user(teacher, "TeacherEnrollment").accept!
      course2 = course_factory(active_all: true)
      course2.enroll_user(teacher, "StudentEnrollment").accept!

      expect(@test_api.user_json(student, teacher, {}, [], course1)).to eq({
                                                                             "name" => "User",
                                                                             "sortable_name" => "User",
                                                                             "id" => student.id,
                                                                             "created_at" => student.created_at.iso8601,
                                                                             "short_name" => "User",
                                                                             "sis_user_id" => "xyz",
                                                                             "integration_id" => nil,
                                                                             "login_id" => "xyz"
                                                                           })

      expect(@test_api.user_json(student, teacher, {}, [], course2)).to eq({
                                                                             "name" => "User",
                                                                             "sortable_name" => "User",
                                                                             "id" => student.id,
                                                                             "created_at" => student.created_at.iso8601,
                                                                             "short_name" => "User"
                                                                           })
    end

    it "shows SIS data to teachers in groups in their courses" do
      student = User.create!(name: "User")
      student.pseudonyms.create!(unique_id: "xyz", account: Account.default) { |p| p.sis_user_id = "xyz" }

      teacher = user_factory
      course1 = course_factory(active_all: true)
      course1.enroll_user(teacher, "TeacherEnrollment").accept!
      course2 = course_factory(active_all: true)
      course2.enroll_user(teacher, "StudentEnrollment").accept!
      group1 = course1.groups.create!(name: "Group 1")
      group2 = course2.groups.create!(name: "Group 2")

      expect(@test_api.user_json(student, teacher, {}, [], group1)).to eq({
                                                                            "name" => "User",
                                                                            "sortable_name" => "User",
                                                                            "id" => student.id,
                                                                            "created_at" => student.created_at.iso8601,
                                                                            "short_name" => "User",
                                                                            "sis_user_id" => "xyz",
                                                                            "integration_id" => nil,
                                                                            "login_id" => "xyz"
                                                                          })

      expect(@test_api.user_json(student, teacher, {}, [], group2)).to eq({
                                                                            "name" => "User",
                                                                            "sortable_name" => "User",
                                                                            "id" => student.id,
                                                                            "created_at" => student.created_at.iso8601,
                                                                            "short_name" => "User"
                                                                          })
    end

    it "uses the SIS pseudonym instead of another pseudonym" do
      @user = User.create!(name: "User")
      @account2 = Account.create!
      @user.pseudonyms.create!(unique_id: "abc", account: Account.default)
      p = @user.pseudonyms.create!(unique_id: "xyz", account: Account.default, sis_user_id: "xyz")
      sis_batch = p.account.sis_batches.create
      SisBatch.where(id: sis_batch).update_all(workflow_state: "imported")
      Pseudonym.where(id: p.id).update_all(sis_batch_id: sis_batch.id)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
                                                                                  "name" => "User",
                                                                                  "sortable_name" => "User",
                                                                                  "sis_import_id" => sis_batch.id,
                                                                                  "id" => @user.id,
                                                                                  "created_at" => @user.created_at.iso8601,
                                                                                  "short_name" => "User",
                                                                                  "sis_user_id" => "xyz",
                                                                                  "integration_id" => nil,
                                                                                  "login_id" => "xyz"
                                                                                })
    end

    it "uses an sis pseudonym from another account if necessary" do
      @user = User.create!(name: "User")
      @account2 = Account.create!
      @user.pseudonyms.destroy_all
      p = @user.pseudonyms.create!(unique_id: "abc", account: @account2, sis_user_id: "a")
      allow(p).to receive(:works_for_account?).with(Account.default, true).and_return(true)
      allow_any_instantiation_of(Account.default).to receive(:trust_exists?).and_return(true)
      allow_any_instantiation_of(Account.default).to receive(:trusted_account_ids).and_return([@account2.id])
      expect(HostUrl).to receive(:context_host).with(@account2).and_return("school1")
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
                                                                                  "name" => "User",
                                                                                  "sortable_name" => "User",
                                                                                  "id" => @user.id,
                                                                                  "created_at" => @user.created_at.iso8601,
                                                                                  "short_name" => "User",
                                                                                  "login_id" => "abc",
                                                                                  "sis_user_id" => "a",
                                                                                  "integration_id" => nil,
                                                                                  "root_account" => "school1",
                                                                                  "sis_import_id" => nil,
                                                                                })
    end

    it "uses the correct pseudonym" do
      @user = User.create!(name: "User")
      @account2 = Account.create!
      @user.pseudonyms.create!(unique_id: "abc", account: @account2)
      @pseudonym = @user.pseudonyms.create!(unique_id: "xyz", account: Account.default)
      allow(SisPseudonym).to receive(:for).with(@user, Account.default, type: :implicit, require_sis: false, root_account: Account.default, in_region: true).and_return(@pseudonym)
      expect(@test_api.user_json(@user, @admin, {}, [], Account.default)).to eq({
                                                                                  "name" => "User",
                                                                                  "sortable_name" => "User",
                                                                                  "id" => @user.id,
                                                                                  "created_at" => @user.created_at.iso8601,
                                                                                  "short_name" => "User",
                                                                                  "integration_id" => nil,
                                                                                  "sis_import_id" => nil,
                                                                                  "sis_user_id" => nil,
                                                                                  "login_id" => "xyz",
                                                                                })
    end

    it "requires :view_user_logins to return login_id" do
      RoleOverride.create!(context: Account.default,
                           role: admin_role,
                           permission: "view_user_logins",
                           enabled: false)
      @user = User.create!(name: "Test User")
      @user.pseudonyms.create!(unique_id: "abc", account: Account.default)
      json = @test_api.user_json(@user, @admin, {}, [], Account.default)
      expect(json.keys).not_to include "login_id"
    end

    context "include[]=email" do
      before :once do
        @user = User.create!(name: "User")
        @user.pseudonyms.create!(unique_id: "abc", account: Account.default)
        @user.communication_channels.create(path: "abc@example.com").confirm!
      end

      it "includes email if requested" do
        json = @test_api.user_json(@user, @admin, {}, ["email"], Account.default)
        expect(json["email"]).to eq "abc@example.com"
      end

      it "does not include email without :read_email_addresses permission" do
        RoleOverride.create!(context: Account.default,
                             role: admin_role,
                             permission: "read_email_addresses",
                             enabled: false)
        json = @test_api.user_json(@user, @admin, {}, ["email"], Account.default)
        expect(json.keys).not_to include "email"
      end
    end

    context "computed scores" do
      before :once do
        assignment_group = @course.assignment_groups.create!
        @student1 = @student
        @student1_enrollment = @student1.enrollments.first
        @student1_enrollment.scores.create! if @student1_enrollment.scores.blank?
        @student1_enrollment.find_score(course_score: true)
                            .update!(current_score: 95.0, final_score: 85.0, unposted_current_score: 90.0, unposted_final_score: 87.0)
        @student1_enrollment.find_score(assignment_group_id: assignment_group.id)
                            .update!(current_score: 50.0, final_score: 40.0, unposted_current_score: 55.0, unposted_final_score: 45.0)
        @student2 = course_with_student(course: @course).user
      end

      before do
        @course.update!(grading_standard_enabled: true)
      end

      it "returns posted course scores as admin" do
        json = @test_api.user_json(@student1, @admin, {}, [], @course, [@student1_enrollment])
        expect(json["enrollments"].first["grades"]).to eq({
                                                            "html_url" => "",
                                                            "current_score" => 95.0,
                                                            "final_score" => 85.0,
                                                            "current_grade" => "A",
                                                            "final_grade" => "B",
                                                            "unposted_current_grade" => "A-",
                                                            "unposted_current_score" => 90.0,
                                                            "unposted_final_grade" => "B+",
                                                            "unposted_final_score" => 87.0
                                                          })
      end

      it "does not return unposted course scores as a student" do
        json = @test_api.user_json(@student1, @student1, {}, [], @course, [@student1_enrollment])
        expect(json["enrollments"].first["grades"]).to eq({
                                                            "html_url" => "",
                                                            "current_score" => 95.0,
                                                            "final_score" => 85.0,
                                                            "current_grade" => "A",
                                                            "final_grade" => "B",
                                                          })
      end

      it "does not return course scores as another student" do
        json = @test_api.user_json(@student1, @student2, {}, [], @course, [@student1_enrollment])
        expect(json["enrollments"].first["grades"].keys).to eq ["html_url"]
      end
    end

    def test_context(mock_context, context_to_pass)
      expect(mock_context).to receive(:account).and_return(mock_context)
      expect(mock_context).to receive(:global_id).and_return(42).twice
      expect(mock_context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis, :view_user_logins).and_return(true)
      expect(mock_context).to receive(:grants_right?).with(@admin, {}, :view_user_logins).and_return(true)
      json = if context_to_pass
               @test_api.user_json(@student, @admin, {}, [], context_to_pass)
             else
               @test_api.user_json(@student, @admin, {}, [])
             end
      expect(json).to eq({
                           "name" => "Sheldon Cooper",
                           "sortable_name" => "Cooper, Sheldon",
                           "id" => @student.id,
                           "created_at" => @student.created_at.iso8601,
                           "short_name" => "Sheldon Cooper",
                           "sis_user_id" => "sis-user-id",
                           "integration_id" => nil,
                           "sis_import_id" => @student.pseudonym.sis_batch_id,
                           "login_id" => "pvuser@example.com"
                         })
    end

    it "supports manually passing the context" do
      mock_context = double
      test_context(mock_context, mock_context)
    end

    it "supports loading the context as a member var" do
      @test_api.context = double
      test_context(@test_api.context, nil)
    end

    it "outputs uuid in json with includes params present" do
      expect(@test_api.user_json(@student, @admin, {}, [], @course)).not_to have_key("uuid")
      expect(@test_api.user_json(@student, @admin, {}, ["uuid"], @course)).to have_key("uuid")
    end

    it "outputs uuid and past_uuid in json with includes params present" do
      expect(@test_api.user_json(@student, @admin, {}, ["uuid"], @course)).not_to have_key("past_uuid")
      UserPastLtiId.create!(user: @student, context: @course, user_lti_id: "old_lti_id", user_lti_context_id: "old_lti_id", user_uuid: "old_uuid")
      expect(@test_api.user_json(@student, @admin, {}, ["uuid"], @course)).to have_key("past_uuid")
    end

    it "outputs last_login in json with includes params present" do
      expect(@test_api.user_json(@student, @admin, {}, [], @course)).not_to have_key("last_login")
      expect(@test_api.user_json(@student, @admin, {}, ["last_login"], @course)).to have_key("last_login")
    end
  end

  describe "enrollment_json" do
    let(:course) { Course.create! }
    let(:student_enrollment) { course_with_user("StudentEnrollment", course:, active_all: true) }
    let(:student) { student_enrollment.user }
    let(:enrollment_json) { @test_api.enrollment_json(student_enrollment, subject, nil) }
    let(:grades) { enrollment_json.fetch("grades") }

    before do
      course.enable_feature!(:final_grades_override)
      course.update!(allow_final_grade_override: true, grading_standard_enabled: true)
      @course_score = student_enrollment.scores.create!(course_score: true, current_score: 63, final_score: 73, override_score: 99)
    end

    context "when user is a classmate" do
      let(:subject) { course_with_user("StudentEnrollment", course:, active_all: true).user }

      it "excludes activity data for other students" do
        expect(enrollment_json).not_to include("last_activity_at", "last_attended_at", "total_activity_time")
      end
    end

    context "when user is the student" do
      let(:subject) { student }

      it "includes student's own activity data" do
        expect(enrollment_json).to include("last_activity_at", "last_attended_at", "total_activity_time")
      end

      context "when Final Grade Override is enabled and allowed" do
        context "when a grade override exists" do
          it "sets the current_grade to the override grade" do
            expect(grades.fetch("current_grade")).to eq "A"
          end

          it "sets the current_score to the override score" do
            expect(grades.fetch("current_score")).to be 99.0
          end

          it "sets the final_grade to the override grade" do
            expect(grades.fetch("final_grade")).to eq "A"
          end

          it "sets the final_score to the override score" do
            expect(grades.fetch("final_score")).to be 99.0
          end

          it "does not include an override_grade key" do
            expect(grades).not_to have_key :override_grade
          end

          it "does not include an override_score key" do
            expect(grades).not_to have_key :override_score
          end
        end

        context "when no grade override exists" do
          before do
            @course_score.update!(override_score: nil)
          end

          it "sets the current_grade to the computed current grade" do
            expect(grades.fetch("current_grade")).to eq "D-"
          end

          it "sets the current_score to the computed current score" do
            expect(grades.fetch("current_score")).to be 63.0
          end

          it "sets the final_grade to the computed final grade" do
            expect(grades.fetch("final_grade")).to eq "C-"
          end

          it "sets the final_score to the computed final score" do
            expect(grades.fetch("final_score")).to be 73.0
          end
        end
      end

      context "when Final Grade Override is not allowed" do
        before do
          course.update!(allow_final_grade_override: false)
        end

        it "sets the current_grade to the computed current grade" do
          expect(grades.fetch("current_grade")).to eq "D-"
        end

        it "sets the current_score to the computed current score" do
          expect(grades.fetch("current_score")).to be 63.0
        end

        it "sets the final_grade to the computed final grade" do
          expect(grades.fetch("final_grade")).to eq "C-"
        end

        it "sets the final_score to the computed final score" do
          expect(grades.fetch("final_score")).to be 73.0
        end
      end

      context "when Final Grade Override is disabled" do
        before do
          course.disable_feature!(:final_grades_override)
        end

        it "sets the current_grade to the computed current grade" do
          expect(grades.fetch("current_grade")).to eq "D-"
        end

        it "sets the current_score to the computed current score" do
          expect(grades.fetch("current_score")).to be 63.0
        end

        it "sets the final_grade to the computed final grade" do
          expect(grades.fetch("final_grade")).to eq "C-"
        end

        it "sets the final_score to the computed final score" do
          expect(grades.fetch("final_score")).to be 73.0
        end
      end
    end

    context "when user is a teacher" do
      let(:subject) { course_with_user("TeacherEnrollment", course:, active_all: true).user }

      it "includes activity data" do
        expect(enrollment_json).to include("last_activity_at", "last_attended_at", "total_activity_time")
      end

      context "when Final Grade Override is enabled and allowed" do
        context "when a grade override exists" do
          it "sets the current_grade to the computed current grade" do
            expect(grades.fetch("current_grade")).to eq "D-"
          end

          it "sets the current_score to the computed current score" do
            expect(grades.fetch("current_score")).to be 63.0
          end

          it "sets the final_grade to the computed final grade" do
            expect(grades.fetch("final_grade")).to eq "C-"
          end

          it "sets the final_score to the computed final score" do
            expect(grades.fetch("final_score")).to be 73.0
          end

          it "sets the override_grade to the override grade" do
            expect(grades.fetch("override_grade")).to eq "A"
          end

          it "sets the override_score to the override score" do
            expect(grades.fetch("override_score")).to be 99.0
          end
        end

        context "when no grade override exists" do
          before do
            @course_score.update!(override_score: nil)
          end

          it "sets the current_grade to the computed current grade" do
            expect(grades.fetch("current_grade")).to eq "D-"
          end

          it "sets the current_score to the computed current score" do
            expect(grades.fetch("current_score")).to be 63.0
          end

          it "sets the final_grade to the computed final grade" do
            expect(grades.fetch("final_grade")).to eq "C-"
          end

          it "sets the final_score to the computed final score" do
            expect(grades.fetch("final_score")).to be 73.0
          end

          it "does not include an override_grade key" do
            expect(grades).not_to have_key :override_grade
          end

          it "does not include an override_score key" do
            expect(grades).not_to have_key :override_score
          end
        end
      end

      context "when Final Grade Override is not allowed" do
        before do
          course.update!(allow_final_grade_override: false)
        end

        it "sets the current_grade to the computed current grade" do
          expect(grades.fetch("current_grade")).to eq "D-"
        end

        it "sets the current_score to the computed current score" do
          expect(grades.fetch("current_score")).to be 63.0
        end

        it "sets the final_grade to the computed final grade" do
          expect(grades.fetch("final_grade")).to eq "C-"
        end

        it "sets the final_score to the computed final score" do
          expect(grades.fetch("final_score")).to be 73.0
        end

        it "does not include an override_grade key" do
          expect(grades).not_to have_key :override_grade
        end

        it "does not include an override_score key" do
          expect(grades).not_to have_key :override_score
        end
      end

      context "when Final Grade Override is disabled" do
        before do
          course.disable_feature!(:final_grades_override)
        end

        it "sets the current_grade to the computed current grade" do
          expect(grades.fetch("current_grade")).to eq "D-"
        end

        it "sets the current_score to the computed current score" do
          expect(grades.fetch("current_score")).to be 63.0
        end

        it "sets the final_grade to the computed final grade" do
          expect(grades.fetch("final_grade")).to eq "C-"
        end

        it "sets the final_score to the computed final score" do
          expect(grades.fetch("final_score")).to be 73.0
        end

        it "does not include an override_grade key" do
          expect(grades).not_to have_key :override_grade
        end

        it "does not include an override_score key" do
          expect(grades).not_to have_key :override_score
        end
      end
    end

    describe "Temporary Enrollments" do
      let_once(:source_user) { user_factory(active_all: true) }
      let_once(:temporary_enrollment_recipient) { user_factory(active_all: true) }
      let_once(:temp_course) { course_with_teacher(active_all: true, user: source_user).course }
      let_once(:temp_enrollment) do
        temp_course.enroll_user(
          temporary_enrollment_recipient,
          "TeacherEnrollment",
          { role: teacher_role, temporary_enrollment_source_user_id: source_user.id }
        )
      end
      let_once(:subject) { account_admin_user(account: temp_course.account) }

      before do
        temp_enrollment.update!(temporary_enrollment_source_user_id: source_user.id)
      end

      context "when feature flag is enabled" do
        before(:once) do
          temp_course.root_account.enable_feature!(:temporary_enrollments)
        end

        it "includes temporary_enrollment_source_user_id attribute" do
          enrollment_json = @test_api.enrollment_json(temp_enrollment.reload, subject, nil)
          expect(enrollment_json).to include("temporary_enrollment_source_user_id")
        end
      end

      context "when feature flag is disabled" do
        before(:once) do
          temp_course.root_account.disable_feature!(:temporary_enrollments)
        end

        it "excludes temporary_enrollment_source_user_id attribute" do
          enrollment_json = @test_api.enrollment_json(temp_enrollment.reload, subject, nil)
          expect(enrollment_json).not_to include("temporary_enrollment_source_user_id")
        end
      end
    end
  end

  context "user_json_is_admin?" do
    it "supports manually passing the current user" do
      @test_api.context = double
      expect(@test_api.context).to receive(:global_id).and_return(42)
      expect(@test_api.context).to receive(:account).and_return(@test_api.context)
      expect(@test_api.context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis, :view_user_logins).and_return(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?).to be true
    end

    it "supports loading the current user as a member var" do
      mock_context = double
      expect(mock_context).to receive(:global_id).and_return(42)
      expect(mock_context).to receive(:account).and_return(mock_context)
      expect(mock_context).to receive(:grants_any_right?).with(@admin, :manage_students, :read_sis, :view_user_logins).and_return(true)
      @test_api.current_user = @admin
      expect(@test_api.user_json_is_admin?(mock_context, @admin)).to be true
    end

    it "supports loading multiple different things (via args)" do
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@student, @admin)).to be_truthy
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
      expect(@test_api.user_json_is_admin?(@admin, @student)).to be_falsey
    end

    it "supports loading multiple different things (via member vars)" do
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      @test_api.current_user = @admin
      @test_api.context = @student
      expect(@test_api.user_json_is_admin?).to be_truthy
      expect(@test_api.user_json_is_admin?).to be_truthy
      @test_api.current_user = @student
      @test_api.context = @admin
      expect(@test_api.user_json_is_admin?).to be_falsey
      expect(@test_api.user_json_is_admin?).to be_falsey
    end
  end
end

describe "Users API", type: :request do
  def avatar_url(id)
    "http://www.example.com/images/users/#{User.avatar_key(id)}?fallback=http%3A%2F%2Fwww.example.com%2Fimages%2Fmessages%2Favatar-50.png"
  end

  before :once do
    @admin = account_admin_user
    course_with_student(user: user_with_pseudonym(name: "Student", username: "pvuser@example.com", active_user: true))
    @student.pseudonym.update_attribute(:sis_user_id, "sis-user-id")
    @user = @admin
    Account.default.tap { |a| a.enable_service(:avatars) }.save
    user_with_pseudonym(user: @user)
  end

  it "does not return disallowed avatars" do
    @user = @student
    raw_api_call(:get,
                 "/api/v1/users/#{@admin.id}/avatars",
                 controller: "profile",
                 action: "profile_pics",
                 user_id: @admin.to_param,
                 format: "json")
    assert_status(401)
  end

  shared_examples_for "page view api" do
    describe "page view api" do
      before do
        @timestamp = Time.zone.at(1.day.ago.to_i)
        page_view_model(user: @student, created_at: @timestamp - 1.day)
        page_view_model(user: @student, created_at: @timestamp + 1.day)
        page_view_model(user: @student, created_at: @timestamp, developer_key: DeveloperKey.default)
      end

      it "returns page view history" do
        stub_const("Api::MAX_PER_PAGE", 2)
        json = api_call(:get,
                        "/api/v1/users/#{@student.id}/page_views?per_page=1000",
                        { controller: "page_views", action: "index", user_id: @student.to_param, format: "json", per_page: "1000" })
        expect(json.size).to eq 2
        json.each { |j| expect(j["url"]).to eq "http://www.example.com/courses/1" }
        expect(json[0]["created_at"]).to be > json[1]["created_at"]
        expect(json[0]["app_name"]).to be_nil
        expect(json[1]["app_name"]).to eq "User-Generated"
        expect(response.headers["Link"]).to match(/next/)
        response.headers["Link"].split(",").find { |l| l =~ /<([^>]+)>.+next/ }
        url = $1
        _path, querystring = url.split("?")
        page = Rack::Utils.parse_nested_query(querystring)["page"]
        json = api_call(:get,
                        url,
                        { controller: "page_views", action: "index", user_id: @student.to_param, format: "json", page:, per_page: Setting.get("api_max_per_page", "2") })
        expect(json.size).to eq 1
        json.each { |j| expect(j["url"]).to eq "http://www.example.com/courses/1" }
        expect(response.headers["Link"]).not_to match(/next/)
        expect(response.headers["Link"]).to match(/last/)
      end

      it "recognizes start_time parameter" do
        stub_const("Api::MAX_PER_PAGE", 3)
        start_time = @timestamp.iso8601
        json = api_call(:get,
                        "/api/v1/users/#{@student.id}/page_views?start_time=#{start_time}",
                        { controller: "page_views", action: "index", user_id: @student.to_param, format: "json", start_time: })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j["created_at"]).to_i).to be >= @timestamp.to_i }
      end

      it "recognizes end_time parameter" do
        stub_const("Api::MAX_PER_PAGE", 3)
        end_time = @timestamp.iso8601
        json = api_call(:get,
                        "/api/v1/users/#{@student.id}/page_views?end_time=#{end_time}",
                        { controller: "page_views", action: "index", user_id: @student.to_param, format: "json", end_time: })
        expect(json.size).to eq 2
        json.each { |j| expect(CanvasTime.try_parse(j["created_at"]).to_i).to be <= @timestamp.to_i }
      end
    end
  end

  include_examples "page view api"

  describe "cassandra page views" do
    before do
      # can't use :once'd @student, since cassandra doesn't reset
      student_in_course(course: @course, user: user_with_pseudonym(name: "Student", username: "pvuser2@example.com", active_user: true))
      @user = @admin
    end

    include_examples "cassandra page views"
    include_examples "page view api"
  end

  it "does not find users in other root accounts by sis id" do
    acct = account_model(name: "other root")
    acct.account_users.create!(user: @user)
    @me = @user
    course_with_student(account: acct, active_all: true, user: user_with_pseudonym(name: "s2", username: "other@example.com"))
    @other_user = @user
    @other_user.pseudonym.update_attribute("sis_user_id", "other-sis")
    @other_user.pseudonym.update_attribute("account_id", acct.id)
    @user = @me
    raw_api_call(:get,
                 "/api/v1/users/sis_user_id:other-sis/page_views",
                 { controller: "page_views", action: "index", user_id: "sis_user_id:other-sis", format: "json" })
    assert_status(404)
  end

  it "allows id of 'self'" do
    page_view_model(user: @admin)
    json = api_call(:get,
                    "/api/v1/users/self/page_views?per_page=1000",
                    { controller: "page_views", action: "index", user_id: "self", format: "json", per_page: "1000" })
    expect(json.size).to eq 1
  end

  describe "api_show" do
    before do
      @other_user = User.create!(name: "user name")

      email = "email@somewhere.org"
      @other_user.pseudonyms.create!(unique_id: email, account: Account.default) { |p| p.sis_user_id = email }
    end

    context "avatars disabled" do
      before do
        Account.default.tap { |a| a.disable_service(:avatars) }.save
      end

      it "retrieves user details as an admin user" do
        account_admin_user
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" })

        expect(json).to eq({
                             "name" => @other_user.name,
                             "sortable_name" => @other_user.sortable_name,
                             "sis_import_id" => nil,
                             "id" => @other_user.id,
                             "created_at" => @other_user.created_at.iso8601,
                             "first_name" => @other_user.first_name,
                             "last_name" => @other_user.last_name,
                             "short_name" => @other_user.short_name,
                             "sis_user_id" => @other_user.pseudonym.sis_user_id,
                             "integration_id" => nil,
                             "login_id" => @other_user.pseudonym.unique_id,
                             "locale" => nil,
                             "permissions" => {
                               "can_update_name" => true,
                               "can_update_avatar" => false,
                               "limit_parent_app_web_access" => false,
                             },
                             "email" => @other_user.email
                           })
      end

      it "retrieves limited user details as self" do
        @user = @other_user
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json", include: "avatar_state" })
        expect(json).to eq({
                             "name" => @other_user.name,
                             "sortable_name" => @other_user.sortable_name,
                             "id" => @other_user.id,
                             "created_at" => @other_user.created_at.iso8601,
                             "first_name" => @other_user.first_name,
                             "last_name" => @other_user.last_name,
                             "short_name" => @other_user.short_name,
                             "locale" => nil,
                             "effective_locale" => "en",
                             "permissions" => {
                               "can_update_name" => true,
                               "can_update_avatar" => false,
                               "limit_parent_app_web_access" => false,
                             },
                           })
      end

      it "retrieves the right permissions" do
        @user = @other_user
        Account.default.tap { |a| a.settings[:users_can_edit_name] = false }.save
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]).to eq({
                                            "can_update_name" => false,
                                            "can_update_avatar" => false,
                                            "limit_parent_app_web_access" => false,
                                          })

        Account.default.tap { |a| a.enable_service(:avatars) }.save
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]).to eq({
                                            "can_update_name" => false,
                                            "can_update_avatar" => true,
                                            "limit_parent_app_web_access" => false,
                                          })

        Account.default.tap { |a| a.settings[:limit_parent_app_web_access] = true }.save
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]).to eq({
                                            "can_update_name" => false,
                                            "can_update_avatar" => true,
                                            "limit_parent_app_web_access" => true,
                                          })
      end

      it "retrieves the right avatar permissions" do
        @user = @other_user
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]["can_update_avatar"]).to be(false)

        Account.default.tap { |a| a.enable_service(:avatars) }.save
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]["can_update_avatar"]).to be(true)

        @user.avatar_state = :locked
        @user.save
        json = api_call(:get,
                        "/api/v1/users/self",
                        { controller: "users", action: "api_show", id: "self", format: "json" })
        expect(json["permissions"]["can_update_avatar"]).to be(false)
      end

      it "requires :read_roster or :manage_user_logins permission from the account" do
        account_admin_user_with_role_changes(role_changes: { read_roster: false, manage_user_logins: false })
        api_call(:get,
                 "/api/v1/users/#{@other_user.id}",
                 { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" },
                 {},
                 {},
                 { expected_status: 404 })
      end

      it "404s on a deleted user" do
        @other_user.destroy
        account_admin_user
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" },
                        {},
                        expected_status: 404)
        expect(json.keys).to include("id")
      end

      it "404s but still returns the user on a deleted user for a site admin" do
        @other_user.destroy
        account_admin_user(account: Account.site_admin)
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" },
                        {},
                        expected_status: 404)
        expect(json.keys).not_to include("errors")
      end

      it "404s but still returns the user on a deleted user, including merge info, for a site admin" do
        u3 = User.create!
        UserMerge.from(@other_user).into(u3)
        account_admin_user(account: Account.site_admin)
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" },
                        {},
                        expected_status: 404)
        expect(json.keys).not_to include("errors")
        expect(json["merged_into_user_id"]).to eq u3.id
      end
    end

    context "avatars enabled" do
      before do
        Account.default.tap { |a| a.enable_service(:avatars) }.save
        @user = Users
      end

      it "does not include avatar_state by default" do
        account_admin_user
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json" })

        expect(json).not_to have_key("avatar_state")
      end

      it "admin can request avatar_state" do
        account_admin_user
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json", include: "avatar_state" })

        expect(json).to have_key("avatar_state")
      end

      it "user cannot request others avatar_state" do
        @user = User.create!
        json = api_call(:get,
                        "/api/v1/users/#{@other_user.id}",
                        { controller: "users", action: "api_show", id: @other_user.id.to_param, format: "json", include: "avatar_state" })

        expect(json).not_to have_key("avatar_state")
      end

      it "user cannot request own avatar_state" do
        @user = User.create!
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}",
                        { controller: "users", action: "api_show", id: @user.id.to_param, format: "json", include: "avatar_state" })

        expect(json).not_to have_key("avatar_state")
      end
    end
  end

  describe "user account listing" do
    it "returns users for an account" do
      @account = Account.default
      users = []
      [["Test User1", "test@example.com"], ["Test User2", "test2@example.com"], ["Test User3", "test3@example.com"]].each_with_index do |u, i|
        users << User.create!(name: u[0])
        users[i].pseudonyms.create!(unique_id: u[1], account: @account) { |p| p.sis_user_id = u[1] }
      end
      @account.all_users.order(:sortable_name).each_with_index do |user, i|
        next unless users.find { |u| u == user }

        json = api_call(:get,
                        "/api/v1/accounts/#{@account.id}/users",
                        { controller: "users", action: "api_index", account_id: @account.id.to_param, format: "json" },
                        { per_page: 1, page: i + 1 })
        expect(json).to eq [{
          "name" => user.name,
          "sortable_name" => user.sortable_name,
          "sis_import_id" => nil,
          "id" => user.id,
          "created_at" => user.created_at.iso8601,
          "short_name" => user.short_name,
          "sis_user_id" => user.pseudonym.sis_user_id,
          "integration_id" => nil,
          "login_id" => user.pseudonym.unique_id
        }]
      end
    end

    it "limits the maximum number of users returned" do
      @account = @user.account
      3.times do |n|
        user = User.create(name: "u#{n}")
        user.pseudonyms.create!(unique_id: "u#{n}@example.com", account: @account)
      end
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", controller: "users", action: "api_index", account_id: @account.id.to_param, format: "json", per_page: "2").size).to eq 2
      stub_const("Api::MAX_PER_PAGE", 1)
      expect(api_call(:get, "/api/v1/accounts/#{@account.id}/users?per_page=2", controller: "users", action: "api_index", account_id: @account.id.to_param, format: "json", per_page: "2").size).to eq 1
    end

    it "returns unauthorized for users without permissions" do
      @account = @student.account
      @user    = @student
      raw_api_call(:get, "/api/v1/accounts/#{@account.id}/users", controller: "users", action: "api_index", account_id: @account.id.to_param, format: "json")
      expect(response).to have_http_status :unauthorized
    end

    it "returns an error when search_term is fewer than 2 characters" do
      @account = Account.default
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { search_term: "a" }, {}, expected_status: 400)
      error = json["errors"].first
      verify_json_error(error, "search_term", "invalid", "2 or more characters is required")
    end

    it "returns a list of users filtered by search_term" do
      @account = Account.default
      expected_keys = %w[id name sortable_name short_name]

      users = []
      [["Test User1", "test@example.com"], ["Test User2", "test2@example.com"], ["Test User3", "test3@example.com"]].each_with_index do |u, i|
        users << User.create!(name: u[0])
        users[i].pseudonyms.create!(unique_id: u[1], account: @account) { |p| p.sis_user_id = u[1] }
      end

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { search_term: "test3@example.com" })

      expect(json.count).to eq 1
      json.each do |user|
        expect((user.keys & expected_keys).sort).to eq expected_keys.sort
        expect(users.map(&:id)).to include(user["id"])
      end
    end

    it "returns a list of users filtered by search_term as integration_id" do
      @account = Account.default
      user = User.create!(name: "Test User")
      user.pseudonyms.create!(unique_id: "test@example.com", account: @account) { |p| p.sis_user_id = "xyz", p.integration_id = "abc" }

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { search_term: "abc" })

      expect(json.count).to eq 1
      expect(json.first["name"]).to eq user.name
    end

    it "returns a list of users filtered by enrollment_type" do
      @account = Account.default
      # student enrollment created in before(:once) block
      teacher_in_course(active_all: true, course: @course)
      ta_in_course(active_all: true, course: @course)
      @user = @admin

      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/users",
                      { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                      { enrollment_type: "student" })

      expect(json.count).to eq 1
      expect(json.pluck("name")).to eq [@student.name]
    end

    it "doesn't kersplode when filtering by role and sorting" do
      @account = Account.default
      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/users",
                      { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                      { role_filter_id: student_role.id.to_s, sort: "sis_id" })

      expect(json.pluck("id")).to eq [@student.id]

      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/users",
                      { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                      { role_filter_id: student_role.id.to_s, sort: "email" })

      expect(json.pluck("id")).to eq [@student.id]
    end

    context "includes ui_invoked" do
      let(:root_account) { Account.default }

      it "sets pagination total_pages/last page link" do
        user_session(@admin)
        api_call(:get,
                 "/api/v1/accounts/#{root_account.id}/users",
                 { controller: "users", action: "api_index", format: "json", account_id: root_account.id.to_param },
                 { role_filter_id: student_role.id.to_s, include: ["ui_invoked"] })
        expect(response).to be_successful
        expect(response.headers["Link"]).to include("last")
      end

      it "includes context account and sub-accounts when filtering by role" do
        subaccount = Account.create!(parent_account: root_account)
        course_with_student(account: subaccount, active_all: true)
        account_admin_user
        user_session(@user)
        json = api_call(:get,
                        "/api/v1/accounts/#{root_account.id}/users",
                        { controller: "users", action: "api_index", format: "json", account_id: root_account.id.to_param },
                        { role_filter_id: student_role.id.to_s, include: ["ui_invoked"] })
        expect(response).to be_successful
        # includes the first describe block student and the new subaccount student user
        expect(json.count).to eq 2
      end
    end

    context "includes last login info" do
      before :once do
        @account = Account.default
        @u = User.create!(name: "test user")
        @p = @u.pseudonyms.create!(account: @account, unique_id: "user")
        @p.current_login_at = 2.minutes.ago
        @p.save!
      end

      it "includes last login" do
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { include: ["last_login"], search_term: @u.id.to_s })
        expect(json.count).to eq 1
        expect(json.first["last_login"]).to eq @p.current_login_at.iso8601
      end

      it "includes last login for a specific user" do
        json = api_call(:get, "/api/v1/users/#{@u.id}", { controller: "users", action: "api_show", format: "json", id: @u.id }, { include: ["last_login"] })
        expect(json.fetch("last_login")).to eq @p.current_login_at.iso8601
      end

      it "sorts too" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@account.id}/users",
                        { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                        { include: ["last_login"], sort: "last_login", order: "desc" })
        expect(json.first["last_login"]).to eq @p.current_login_at.iso8601
      end

      it "includes automatically when sorting by last login" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@account.id}/users",
                        { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                        { sort: "last_login", order: "desc" })
        expect(json.first["last_login"]).to eq @p.current_login_at.iso8601
      end

      it "works with search terms" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@account.id}/users",
                        { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                        { sort: "last_login", order: "desc", search_term: "test" })
        expect(json.first["last_login"]).to eq @p.current_login_at.iso8601
      end

      it "does not include last_logins from a different account" do
        account = @account
        p2 = @u.pseudonyms.create!(account: account_model, unique_id: "user")
        p2.current_login_at = Time.now.utc
        p2.save!

        json = api_call(:get,
                        "/api/v1/accounts/#{account.id}/users",
                        { controller: "users", action: "api_index", format: "json", account_id: account.id.to_param },
                        { include: ["last_login"], order: "desc", search_term: "test" })
        expect(json.first["last_login"]).to eq @p.current_login_at.iso8601
      end

      context "sharding" do
        specs_require_sharding

        it "takes all relevant pseudonyms and return the maximum current_login_at" do
          @shard1.activate do
            p4 = @u.pseudonyms.create!(account: @account, unique_id: "p4")
            p4.current_login_at = 4.minutes.ago
            p4.save!
            @u.pseudonyms.create!(account: @account, unique_id: "p5") # never logged in
          end
          @shard2.activate do
            account = Account.create!
            allow(account).to receive_messages(trust_exists?: true, trusted_account_ids: [@account.id])
            course = account.courses.create!
            course.enroll_student(@u)
            p2 = @u.pseudonyms.create!(account:, unique_id: "p2")
            p2.current_login_at = 5.minutes.ago
            p2.save!
            p3 = @u.pseudonyms.create!(account:, unique_id: "p3")
            p3.current_login_at = 6.minutes.ago
            p3.save!
          end

          account = Account.create!
          course = account.courses.create!
          course.enroll_student(@u)

          account_admin_user
          user_session(@user)

          json =
            api_call(
              :get,
              "/api/v1/users/#{@u.id}",
              {
                controller: "users",
                action: "api_show",
                id: @u.id.to_param,
                format: "json"
              },
              { include: ["last_login"] }
            )
          expect(json.fetch("last_login")).to eq @p.current_login_at.iso8601
        end
      end

      describe "Temporary Enrollments" do
        let_once(:temporary_enrollment_provider) { user_factory(name: "provider", active_all: true) }
        let_once(:temporary_enrollment_recipient) { user_factory(name: "recipient", active_all: true) }
        let_once(:temp_course) { course_with_teacher(active_all: true, user: temporary_enrollment_provider).course }
        let_once(:temp_enrollment) do
          temp_course.enroll_user(
            temporary_enrollment_recipient,
            "TeacherEnrollment",
            { role: teacher_role, temporary_enrollment_source_user_id: temporary_enrollment_provider.id }
          )
        end
        let_once(:subject) { account_admin_user(account: temp_course.account) }

        before do
          temp_enrollment.update!(temporary_enrollment_source_user_id: temporary_enrollment_provider.id)
        end

        context "when feature flag is enabled" do
          before(:once) do
            temp_course.root_account.enable_feature!(:temporary_enrollments)
          end

          it "returns a list of users filtered by recipients" do
            json = api_call_as_user(
              subject,
              :get,
              "/api/v1/accounts/#{@account.id}/users",
              { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
              { temporary_enrollment_recipients: true }
            )
            expect(json.count).to eq 1
            expect(json.pluck("name")).to eq [temporary_enrollment_recipient.name]
          end

          it "returns a list of users filtered by providers" do
            json = api_call_as_user(
              subject,
              :get,
              "/api/v1/accounts/#{@account.id}/users",
              { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
              { temporary_enrollment_providers: true }
            )
            expect(json.count).to eq 1
            expect(json.pluck("name")).to eq [temporary_enrollment_provider.name]
          end

          it "returns a list of users filtered by providers and recipients" do
            json = api_call_as_user(
              subject,
              :get,
              "/api/v1/accounts/#{@account.id}/users",
              { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
              { temporary_enrollment_recipients: true, temporary_enrollment_providers: true }
            )
            expect(json.count).to eq 2
            expect(json.pluck("name").sort).to eq [temporary_enrollment_provider.name, temporary_enrollment_recipient.name].sort
          end

          it "returns only active or pending by date enrollments" do
            temp_enrollment.enrollment_state.update!(state: "completed")
            json = api_call_as_user(
              subject,
              :get,
              "/api/v1/accounts/#{@account.id}/users",
              { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
              { temporary_enrollment_recipients: true }
            )
            expect(json.count).to eq 0
          end
        end

        context "when feature flag is disabled" do
          before(:once) do
            temp_course.root_account.disable_feature!(:temporary_enrollments)
          end

          it "does not filter by providers or recipients" do
            json = api_call_as_user(
              subject,
              :get,
              "/api/v1/accounts/#{@account.id}/users",
              { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
              { temporary_enrollment_recipients: true, temporary_enrollment_providers: true }
            )
            expect(json.size).to eq 7
          end
        end
      end
    end

    it "does return a next header on the last page" do
      @account = Account.default
      u = User.create!(name: "test user")
      u.pseudonyms.create!(account: @account, unique_id: "user")

      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { search_term: u.id.to_s, per_page: "1", page: "1" })
      expect(json.length).to eq 1
      expect(response.headers["Link"]).to include("rel=\"next\"")
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/users", { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param }, { search_term: u.id.to_s, per_page: "1", page: "2" })
      expect(json).to be_empty
      expect(response.headers["Link"]).to_not include("rel=\"next\"")
    end

    it "does not return a next-page link on the last page" do
      Setting.set("ui_invoked_count_pages", "true")
      @account = Account.default
      u = User.create!(name: "test user")
      u.pseudonyms.create!(account: @account, unique_id: "user")

      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/users",
                      { controller: "users", action: "api_index", format: "json", account_id: @account.id.to_param },
                      { search_term: u.id.to_s, per_page: "1", page: "1", include: ["ui_invoked"] })
      expect(json.length).to eq 1
      expect(response.headers["Link"]).to_not include("rel=\"next\"")
    end
  end

  describe "user account creation" do
    def create_user_skip_cc_confirm(admin_user)
      api_call(:post,
               "/api/v1/accounts/#{admin_user.account.id}/users",
               { controller: "users", action: "create", format: "json", account_id: admin_user.account.id.to_s },
               {
                 user: {
                   name: "Test User",
                   short_name: "Test",
                   sortable_name: "User, T.",
                   time_zone: "Mountain Time (US & Canada)",
                   locale: "en"
                 },
                 pseudonym: {
                   unique_id: "test@example.com",
                   password: "password123",
                   sis_user_id: "12345",
                   send_confirmation: 0
                 },
                 communication_channel: {
                   type: "sms",
                   address: "8018888888",
                   skip_confirmation: 1
                 }
               })
      users = User.where(name: "Test User").to_a
      expect(users.length).to be 1
      user = users.first
      expect(user.sms_channel.workflow_state).to eq "active"
    end

    context "as a site admin" do
      before :once do
        @site_admin = user_with_pseudonym
        Account.site_admin.account_users.create!(user: @site_admin)
      end

      context "using force_validations param" do
        it "validates with force_validations set to true" do
          @site_admin.account.create_terms_of_service!(terms_type: "default", passive: false)
          raw_api_call(:post,
                       "/api/v1/accounts/#{@site_admin.account.id}/users",
                       { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                       {
                         user: {
                           name: ""
                         },
                         pseudonym: {
                           unique_id: "bademail@",
                         },
                         force_validations: true
                       })

          assert_status(400)
          errors = JSON.parse(response.body)["errors"]
          expect(errors["user"]["name"]).to be_present
          expect(errors["user"]["terms_of_use"]).to be_present
          expect(errors["pseudonym"]).to be_present
          expect(errors["pseudonym"]["unique_id"]).to be_present
        end

        it "does not validate when force_validations is not set to true" do
          # successful request even with oddball user params because we're making the request as an admin
          json = api_call(:post,
                          "/api/v1/accounts/#{@site_admin.account.id}/users",
                          { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                          {
                            user: {
                              name: ""
                            },
                            pseudonym: {
                              unique_id: "bademail@",
                            }
                          })

          users = User.where(name: "").to_a
          expect(users.length).to be 1
          user = users.first

          expect(json).to eq({
                               "id" => user.id,
                               "created_at" => user.created_at.iso8601,
                               "integration_id" => nil,
                               "name" => "",
                               "sortable_name" => "",
                               "short_name" => "",
                               "sis_import_id" => nil,
                               "sis_user_id" => nil,
                               "login_id" => "bademail@",
                               "locale" => nil,
                               "uuid" => user.uuid
                             })
        end
      end

      it "allows site admins to create users" do
        api_call(:post,
                 "/api/v1/accounts/#{@site_admin.account.id}/users",
                 { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                 {
                   user: {
                     name: "Test User",
                     short_name: "Test",
                     sortable_name: "User, T.",
                     time_zone: "Mountain Time (US & Canada)",
                     locale: "en"
                   },
                   pseudonym: {
                     unique_id: "test@example.com",
                     password: "password123",
                     sis_user_id: "12345",
                     send_confirmation: 0
                   },
                   communication_channel: {
                     confirmation_url: true
                   }
                 })
        users = User.where(name: "Test User").to_a
        expect(users.length).to be 1
        user = users.first
        expect(user.name).to eql "Test User"
        expect(user.short_name).to eql "Test"
        expect(user.sortable_name).to eql "User, T."
        expect(user.time_zone.name).to eql "Mountain Time (US & Canada)"
        expect(user.locale).to eql "en"

        expect(user.pseudonyms.count).to be 1
        pseudonym = user.pseudonyms.first
        expect(pseudonym.unique_id).to eql "test@example.com"
        expect(pseudonym.sis_user_id).to eql "12345"

        expect(JSON.parse(response.body)).to eq({
                                                  "name" => "Test User",
                                                  "short_name" => "Test",
                                                  "sortable_name" => "User, T.",
                                                  "id" => user.id,
                                                  "created_at" => user.created_at.iso8601,
                                                  "sis_user_id" => "12345",
                                                  "sis_import_id" => user.pseudonym.sis_batch_id,
                                                  "login_id" => "test@example.com",
                                                  "integration_id" => nil,
                                                  "locale" => "en",
                                                  "confirmation_url" => user.communication_channels.email.first.confirmation_url,
                                                  "uuid" => user.uuid
                                                })
      end

      it "accepts a valid destination param" do
        json = api_call(:post,
                        "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: "http://www.example.com/courses/1"
                        })
        expect(json["destination"]).to start_with("http://www.example.com/courses/1?session_token=")
      end

      it "ignores a destination with a mismatched host" do
        json = api_call(:post,
                        "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: "http://hacker.com/courses/1"
                        })
        expect(json["destination"]).to be_nil
      end

      it "ignores a destination with an unrecognized path" do
        json = api_call(:post,
                        "/api/v1/accounts/#{@site_admin.account.id}/users",
                        { controller: "users", action: "create", format: "json", account_id: @site_admin.account.id.to_s },
                        {
                          user: {
                            name: "Test User",
                          },
                          pseudonym: {
                            unique_id: "test@example.com",
                            password: "password123",
                          },
                          destination: "http://www.example.com/hacker/1"
                        })
        expect(json["destination"]).to be_nil
      end

      context "sis reactivation" do
        it "allows reactivating deleting users using sis_user_id" do
          other_user = user_with_pseudonym(active_all: true)
          @pseudonym.sis_user_id = "12345"
          @pseudonym.save!
          @user.communication_channel.workflow_state = "registered"
          other_user.remove_from_root_account(Account.default)
          expect(other_user.communication_channel).to be_nil

          @user = @site_admin
          json = api_call(:post,
                          "/api/v1/accounts/#{Account.default.id}/users",
                          { controller: "users", action: "create", format: "json", account_id: Account.default.id.to_s },
                          { enable_sis_reactivation: "1",
                            user: { name: "Test User", skip_registration: true },
                            pseudonym: { unique_id: "test@example.com", password: "password123", sis_user_id: "12345" },
                            communication_channel: { skip_confirmation: true } })

          expect(other_user).to eq User.find(json["id"])
          other_user.reload
          @pseudonym.reload
          expect(other_user).to be_registered
          expect(other_user.user_account_associations.where(account_id: Account.default).first).to_not be_nil
          expect(@pseudonym).to be_active
          expect(other_user.communication_channel).to be_present
          expect(other_user.communication_channel.workflow_state).to eq("active")
        end

        it "raises an error trying to reactivate an active section" do
          user_with_pseudonym(active_all: true)
          @pseudonym.sis_user_id = "12345"
          @pseudonym.save!

          @user = @site_admin
          api_call(:post,
                   "/api/v1/accounts/#{Account.default.id}/users",
                   { controller: "users", action: "create", format: "json", account_id: Account.default.id.to_s },
                   { enable_sis_reactivation: "1",
                     user: { name: "Test User" },
                     pseudonym: { unique_id: "test@example.com", password: "password123", sis_user_id: "12345" }, },
                   {},
                   { expected_status: 400 })
        end

        it "carries on if there's no section to reactivate" do
          json = api_call(:post,
                          "/api/v1/accounts/#{Account.default.id}/users",
                          { controller: "users", action: "create", format: "json", account_id: Account.default.id.to_s },
                          { enable_sis_reactivation: "1",
                            user: { name: "Test User" },
                            pseudonym: { unique_id: "test@example.com", password: "password123", sis_user_id: "12345" }, })

          user = User.find(json["id"])
          expect(user.pseudonym.sis_user_id).to eq "12345"
        end
      end

      it "allows site admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@site_admin)
      end

      context "sharding" do
        specs_require_sharding
        it "allows creating users on cross-shard accounts" do
          @other_account = @shard1.activate { Account.create! }
          json = api_call(:post,
                          "/api/v1/accounts/#{@other_account.id}/users",
                          { controller: "users", action: "create", format: "json", account_id: @other_account.id.to_s },
                          { user: { name: "Test User" }, pseudonym: { unique_id: "test@example.com", password: "password123" } })
          new_user = User.find(json["id"])
          expect(new_user.shard).to eq @shard1
          expect(new_user.pseudonym.account).to eq @other_account
        end

        it "does not error when there is not a local pseudonym" do
          @user = User.create!(name: "default shard user")
          @shard1.activate do
            account = Account.create!
            @pseudonym = account.pseudonyms.create!(user: @user, unique_id: "so_unique@example.com")
          end
          # We need to return the pseudonym here, or one is created from the api_call method,
          # or we'd need to setup more stuff in a plugin that would make this return happen without the allow method
          allow(SisPseudonym).to receive(:for).with(@user, Account.default, type: :implicit, require_sis: false).and_return(@pseudonym)
          api_call(:put,
                   "/api/v1/users/#{@user.id}",
                   { controller: "users", action: "update", format: "json", id: @user.id.to_s },
                   { user: { name: "Test User" } })
          expect(response).to be_successful
        end
      end

      it "respects authentication_provider_id" do
        ap = Account.site_admin.authentication_providers.create!(auth_type: "facebook")
        api_call(:post,
                 "/api/v1/accounts/#{Account.site_admin.id}/users",
                 { controller: "users", action: "create", format: "json", account_id: Account.site_admin.id.to_s },
                 {
                   user: {
                     name: "Test User",
                     short_name: "Test",
                     sortable_name: "User, T.",
                     time_zone: "Mountain Time (US & Canada)",
                     locale: "en"
                   },
                   pseudonym: {
                     unique_id: "test@example.com",
                     password: "password123",
                     sis_user_id: "12345",
                     send_confirmation: 0,
                     authentication_provider_id: "facebook"
                   },
                   communication_channel: {
                     type: "sms",
                     address: "8018888888",
                     skip_confirmation: 1
                   }
                 })
        users = User.where(name: "Test User").to_a
        expect(users.length).to be 1
        user = users.first
        expect(user.pseudonyms.first.authentication_provider).to eq ap
      end
    end

    context "as an account admin" do
      it "allows account admins to create users and auto-validate communication channel" do
        create_user_skip_cc_confirm(@admin)
      end
    end

    context "as a non-administrator" do
      before :once do
        user_factory(active_all: true)
      end

      it "does not let you create a user if self_registration is off" do
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/users",
                     { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User" },
                       pseudonym: { unique_id: "test@example.com" }
                     })
        assert_status(403)
      end

      it "requires an email pseudonym" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.save!
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/users",
                     { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User", terms_of_use: "1" },
                       pseudonym: { unique_id: "invalid" }
                     })
        assert_status(400)
      end

      it "requires acceptance of the terms" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.create_terms_of_service!(terms_type: "default", passive: false)
        @admin.account.save!
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/users",
                     { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User" },
                       pseudonym: { unique_id: "test@example.com" }
                     })
        assert_status(400)
      end

      it "lets you create a user if you pass all the validations" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        @admin.account.save!
        json = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/users",
                        { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
                        {
                          user: { name: "Test User", terms_of_use: "1" },
                          pseudonym: { unique_id: "test@example.com" }
                        })
        expect(json["name"]).to eq "Test User"
      end
    end

    it "sends a confirmation if send_confirmation is set to 1" do
      expect_any_instance_of(Pseudonym).to receive(:send_registration_done_notification!)
      api_call(:post,
               "/api/v1/accounts/#{@admin.account.id}/users",
               { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
               {
                 user: {
                   name: "Test User"
                 },
                 pseudonym: {
                   unique_id: "test@example.com",
                   password: "password123",
                   send_confirmation: 1
                 }
               })
    end

    it "returns a 400 error if the request doesn't include a unique id" do
      raw_api_call(:post,
                   "/api/v1/accounts/#{@admin.account.id}/users",
                   { controller: "users", action: "create", format: "json", account_id: @admin.account.id.to_s },
                   {
                     user: { name: "Test User" },
                     pseudonym: { password: "password123" }
                   })
      assert_status(400)
      errors = JSON.parse(response.body)["errors"]
      expect(errors["pseudonym"]).to be_present
      expect(errors["pseudonym"]["unique_id"]).to be_present
    end

    it "sets user's email address via communication_channel[address]" do
      api_call(:post,
               "/api/v1/accounts/#{@admin.account.id}/users",
               { controller: "users",
                 action: "create",
                 format: "json",
                 account_id: @admin.account.id.to_s },
               {
                 user: {
                   name: "Test User"
                 },
                 pseudonym: {
                   unique_id: "test",
                   password: "password123"
                 },
                 communication_channel: {
                   address: "test@example.com"
                 }
               })
      expect(response).to be_successful
      users = User.where(name: "Test User").to_a
      expect(users.size).to eq 1
      expect(users.first.pseudonyms.first.unique_id).to eq "test"
      email = users.first.communication_channels.email.first
      expect(email.path).to eq "test@example.com"
      expect(email.path_type).to eq "email"
    end

    context "as an anonymous user" do
      before do
        user_factory(active_all: true)
        @user = nil
      end

      it "does not let you create a user if self_registration is off" do
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { controller: "users", action: "create_self_registered_user", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User" },
                       pseudonym: { unique_id: "test@example.com" }
                     })
        assert_status(403)
      end

      it "requires an email pseudonym" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { controller: "users", action: "create_self_registered_user", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User", terms_of_use: "1" },
                       pseudonym: { unique_id: "invalid" }
                     })
        assert_status(400)
      end

      it "requires acceptance of the terms" do
        @admin.account.create_terms_of_service!(terms_type: "default", passive: false)
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { controller: "users", action: "create_self_registered_user", format: "json", account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User" },
                       pseudonym: { unique_id: "test@example.com" }
                     })
        assert_status(400)
      end

      it "lets you create a user if you pass all the validations" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        json = api_call(:post,
                        "/api/v1/accounts/#{@admin.account.id}/self_registration",
                        { controller: "users", action: "create_self_registered_user", format: "json", account_id: @admin.account.id.to_s },
                        {
                          user: { name: "Test User", terms_of_use: "1" },
                          pseudonym: { unique_id: "test@example.com" }
                        })
        expect(json["name"]).to eq "Test User"
      end

      it "returns a 400 error if the request doesn't include a unique id" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        raw_api_call(:post,
                     "/api/v1/accounts/#{@admin.account.id}/self_registration",
                     { controller: "users",
                       action: "create_self_registered_user",
                       format: "json",
                       account_id: @admin.account.id.to_s },
                     {
                       user: { name: "Test User", terms_of_use: "1" },
                       pseudonym: { password: "password123" }
                     })
        assert_status(400)
        errors = JSON.parse(response.body)["errors"]
        expect(errors["pseudonym"]).to be_present
        expect(errors["pseudonym"]["unique_id"]).to be_present
      end

      it "sets user's email address via communication_channel[address]" do
        @admin.account.canvas_authentication_provider.update_attribute(:self_registration, true)
        api_call(:post,
                 "/api/v1/accounts/#{@admin.account.id}/self_registration",
                 { controller: "users",
                   action: "create_self_registered_user",
                   format: "json",
                   account_id: @admin.account.id.to_s },
                 {
                   user: { name: "Test User", terms_of_use: "1" },
                   pseudonym: {
                     unique_id: "test@test.com",
                     password: "password123"
                   },
                   communication_channel: {
                     address: "test@example.com"
                   }
                 })
        expect(response).to be_successful
        users = User.where(name: "Test User").to_a
        expect(users.size).to eq 1
        expect(users.first.pseudonyms.first.unique_id).to eq "test@test.com"
        email = users.first.communication_channels.email.first
        expect(email.path).to eq "test@example.com"
        expect(email.path_type).to eq "email"
      end
    end
  end

  describe "user account updates" do
    before :once do
      # an outer before sets this
      @student.pseudonym.update_attribute(:sis_user_id, nil)

      @admin = account_admin_user
      course_with_student(user: user_with_pseudonym(name: "Student", username: "student@example.com"))
      @student = @user
      @student.pseudonym.update_attribute(:sis_user_id, "sis-user-id")
      @user = @admin
      @path = "/api/v1/users/#{@student.id}"
      @path_options = { controller: "users", action: "update", format: "json", id: @student.id.to_param }
      user_with_pseudonym(user: @user, username: "admin@example.com")
    end

    context "an admin user" do
      it "is able to update a user" do
        birthday = Time.now
        json = api_call(:put, @path, @path_options, {
                          user: {
                            name: "Tobias Funke",
                            short_name: "Tobias",
                            sortable_name: "Funke, Tobias",
                            time_zone: "Tijuana",
                            birthdate: birthday.iso8601,
                            locale: "en",
                            email: "somenewemail@example.com"
                          }
                        })
        user = User.find(json["id"])
        json.delete("avatar_url")
        expect(json).to eq({
                             "avatar_state" => "none",
                             "name" => "Tobias Funke",
                             "sortable_name" => "Funke, Tobias",
                             "sis_user_id" => "sis-user-id",
                             "sis_import_id" => nil,
                             "id" => user.id,
                             "created_at" => user.created_at.iso8601,
                             "short_name" => "Tobias",
                             "integration_id" => nil,
                             "login_id" => "student@example.com",
                             "email" => "somenewemail@example.com",
                             "locale" => "en",
                             "time_zone" => "Tijuana"
                           })

        expect(user.time_zone.name).to eql "Tijuana"
      end

      it "is able to update email alone" do
        enable_cache do
          @student.email

          Timecop.freeze(5.seconds.from_now) do
            new_email = "bloop@shoop.whoop"
            json = api_call(:put, @path, @path_options, {
                              user: { email: new_email }
                            })
            expect(json["email"]).to eq new_email
            user = User.find(json["id"])
            expect(user.email).to eq new_email
          end
        end
      end

      context "pronouns" do
        context "when can_change_pronouns=true" do
          before :once do
            Account.default.tap do |a|
              a.settings[:can_add_pronouns] = true
              a.settings[:can_change_pronouns] = true
              a.save!
            end
          end

          it "clears attribute when empty string is passed" do
            @student.pronouns = "He/Him"
            @student.save!
            json = api_call(:put, @path, @path_options, { user: { pronouns: "" } })
            expect(json["pronouns"]).to be_nil
            expect(@student.reload.pronouns).to be_nil
          end

          it "updates with a default pronoun" do
            approved_pronoun = "He/Him"
            json = api_call(:put, @path, @path_options, { user: { pronouns: approved_pronoun } })
            expect(json["pronouns"]).to eq approved_pronoun
            expect(@student.reload.pronouns).to eq approved_pronoun
            expect(@student.read_attribute(:pronouns)).to eq "he_him"
          end

          it "fixes the case when pronoun does not match default pronoun case" do
            wrong_case_pronoun = "he/him"
            expected_pronoun = "He/Him"
            json = api_call(:put, @path, @path_options, { user: { pronouns: wrong_case_pronoun } })
            expect(json["pronouns"]).to eq expected_pronoun
            expect(@student.reload.pronouns).to eq expected_pronoun
            expect(@student.read_attribute(:pronouns)).to eq "he_him"
          end

          it "fixes the case when pronoun does not match custom pronoun case" do
            Account.default.tap do |a|
              a.pronouns = ["Siya/Siya", "Ito/Iyan"]
              a.save!
            end
            wrong_case_pronoun = "ito/iyan"
            expected_pronoun = "Ito/Iyan"
            json = api_call(:put, @path, @path_options, { user: { pronouns: wrong_case_pronoun } })
            expect(json["pronouns"]).to eq expected_pronoun
            expect(@student.reload.pronouns).to eq expected_pronoun
            expect(@student.read_attribute(:pronouns)).to eq expected_pronoun
          end

          it "does not update when pronoun is not approved" do
            @student.pronouns = "She/Her"
            @student.save!
            original_pronoun = @student.pronouns
            unapproved_pronoun = "Unapproved/Unapproved"
            json = api_call(:put, @path, @path_options, { user: { pronouns: unapproved_pronoun } })
            expect(json["pronouns"]).to eq original_pronoun
            expect(@student.reload.pronouns).to eq original_pronoun
          end
        end

        context "when can_change_pronouns=false" do
          before :once do
            Account.default.tap do |a|
              a.settings[:can_add_pronouns] = true
              a.settings[:can_change_pronouns] = false
              a.save!
            end
          end

          it "errors" do
            @student.pronouns = "She/Her"
            @student.save!
            original_pronoun = @student.pronouns
            test_pronoun = "He/Him"
            raw_api_call(:put, @path, @path_options, { user: { pronouns: test_pronoun } })
            json = JSON.parse(response.body)
            expect(response).to have_http_status :unauthorized
            expect(json["status"]).to eq "unauthorized"
            expect(json["errors"][0]["message"]).to eq "user not authorized to perform that action"
            expect(@student.reload.pronouns).to eq original_pronoun
          end
        end
      end

      it "is able to update a user's profile" do
        Account.default.tap do |a|
          a.settings[:enable_profiles] = true
          a.save!
        end
        new_title = "Burninator"
        new_bio = "burninating the countryside"
        json = api_call(:put, @path, @path_options, {
                          user: { title: new_title, bio: new_bio }
                        })
        expect(json["title"]).to eq new_title
        expect(json["bio"]).to eq new_bio
        user = User.find(json["id"])
        expect(user.profile.title).to eq new_title
        expect(user.profile.bio).to eq new_bio

        another_title = "another title"
        api_call(:put, @path, @path_options, {
                   user: { title: another_title }
                 })
        expect(user.profile.reload.title).to eq another_title
      end

      it "is able to update a user's profile with email" do
        Account.default.tap do |a|
          a.settings[:enable_profiles] = true
          a.save!
        end
        new_title = "Burninator"
        new_bio = "burninating the countryside"
        email = "dudd@example.com"
        json = api_call(:put, @path, @path_options, {
                          user: { title: new_title, bio: new_bio, email: }
                        })
        expect(json["title"]).to eq new_title
        expect(json["bio"]).to eq new_bio
        expect(json["email"]).to eq email
        user = User.find(json["id"])
        expect(user.profile.title).to eq new_title
        expect(user.profile.bio).to eq new_bio

        another_title = "another title"
        another_bio = "another bio"
        another_email = "duddett@example.com"
        api_call(:put, @path, @path_options, {
                   user: { title: another_title, bio: another_bio, email: another_email }
                 })
        expect(user.profile.reload.title).to eq another_title
      end

      it "allows updating without any params" do
        json = api_call(:put, @path, @path_options, {})
        expect(json).not_to be_nil
      end

      it "updates the user's avatar with a token" do
        json = api_call(:get,
                        "/api/v1/users/#{@student.id}/avatars",
                        controller: "profile",
                        action: "profile_pics",
                        user_id: @student.to_param,
                        format: "json")
        to_set = json.first

        expect(@student.avatar_image_source).not_to eql to_set["type"]
        json = api_call(:put, @path, @path_options, {
                          user: {
                            avatar: {
                              token: to_set["token"]
                            }
                          }
                        })
        user = User.find(json["id"])
        expect(user.avatar_image_source).to eql to_set["type"]
        expect(user.avatar_state).to be :approved
      end

      it "re-locks the avatar after being updated by an admin" do
        json = api_call(:get,
                        "/api/v1/users/#{@student.id}/avatars",
                        controller: "profile",
                        action: "profile_pics",
                        user_id: @student.to_param,
                        format: "json")
        to_set = json.first

        old_source = (to_set["type"] == "gravatar") ? "twitter" : "gravatar"
        @student.avatar_image_source = old_source
        @student.avatar_state = "locked"
        @student.save!

        expect(@student.avatar_image_source).not_to eql to_set["type"]
        json = api_call(:put, @path, @path_options, {
                          user: {
                            avatar: {
                              token: to_set["token"]
                            }
                          }
                        })
        user = User.find(json["id"])
        expect(user.avatar_image_source).to eql to_set["type"]
        expect(user.avatar_state).to be :locked
      end

      it "sets avatar state manually by an admin" do
        @student.avatar_state = "approved"
        @student.save!
        json = api_call(:put, @path, @path_options, {
                          user: {
                            avatar: {
                              state: "locked"
                            }
                          }
                        })
        user = User.find(json["id"])
        expect(user.avatar_state).to be :locked
      end

      it "retains avatar image_url on user update" do
        image_url = "http://localhost/images/thumbnails/27/wRx60Hn9sqs6OJMaEndzKz62hatAJSC7BNanraCD"
        image_source = "attachment"
        state = :approved
        @student.avatar_image_url = image_url
        @student.avatar_image_source = image_source
        @student.avatar_state = state
        @student.avatar_image_updated_at = Time.now.utc
        @student.save!
        json = api_call(:put, @path, @path_options, { user: { name: "New Name", email: "somenewemail@example.com" } })
        user = User.find(json["id"])
        expect(user.avatar_state).to eq state
        expect(user.avatar_image_url).to eq image_url
        expect(user.avatar_image_source).to eq image_source
      end

      it "does not allow the user's avatar to be set to an external url" do
        url_to_set = "https://www.instructure.example.com/image.jpg"
        json = api_call(:put, @path, @path_options, {
                          user: {
                            avatar: {
                              url: url_to_set
                            }
                          }
                        })
        user = User.find(json["id"])
        expect(user.avatar_image_source).to eql "no_pic"
        expect(user.avatar_image_url).to be_nil
      end

      it "is able to update a name without changing sortable name if sent together" do
        sortable = "Name, Sortable"
        @student.update(name: "Sortable Name", sortable_name: sortable)
        api_call(:put, @path, @path_options, {
                   user: { name: "Other Name", sortable_name: sortable }
                 })
        expect(@student.reload.sortable_name).to eq sortable

        @student.update(name: "Sortable Name", sortable_name: sortable) # reset
        api_call(:put, @path, @path_options, { user: { name: "Other Name" } }) # only send in the name
        expect(@student.reload.sortable_name).to eq "Name, Other" # should auto sync
      end

      it "can suspend all pseudonyms" do
        api_call(:put, @path, @path_options, { user: { event: "suspend" } })
        expect(@student.pseudonym.reload).to be_suspended
      end

      it "can unsuspend all pseudonyms" do
        @student.pseudonym.update!(workflow_state: "suspended")
        api_call(:put, @path, @path_options, { user: { event: "unsuspend" } })
        expect(@student.pseudonym.reload).to be_active
      end
    end

    context "non-account-admin user" do
      before :once do
        user_with_pseudonym name: "Earnest Lambert Watkins"
        course_with_teacher user: @user, active_all: true
      end

      context "pronouns" do
        it "returns an error when user does not have manage rights" do
          Account.default.tap do |a|
            a.settings[:can_add_pronouns] = true
            a.settings[:can_change_pronouns] = true
            a.save!
          end

          @student.pronouns = "She/Her"
          @student.save!
          original_pronoun = @student.pronouns
          test_pronoun = "He/Him"
          raw_api_call(:put, @path, @path_options, { user: { pronouns: test_pronoun } })
          json = JSON.parse(response.body)
          expect(response).to have_http_status :unauthorized
          expect(json["status"]).to eq "unauthorized"
          expect(json["errors"][0]["message"]).to eq "user not authorized to perform that action"
          expect(@student.reload.pronouns).to eq original_pronoun
        end
      end

      context "with users_can_edit_name enabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: true }
          @course.root_account.save!
        end

        it "allows user to rename self" do
          json = api_call(:put,
                          "/api/v1/users/#{@user.id}",
                          @path_options.merge(id: @user.id),
                          { user: { name: "Blue Ivy Carter" } })
          expect(json["name"]).to eq "Blue Ivy Carter"
        end
      end

      context "with users_can_edit_name disabled" do
        before :once do
          @course.root_account.settings = { users_can_edit_name: false }
          @course.root_account.save!
        end

        it "does not allow user to rename self" do
          api_call(:put,
                   "/api/v1/users/#{@user.id}",
                   @path_options.merge(id: @user.id),
                   { user: { name: "Ovaltine Jenkins" } },
                   {},
                   { expected_status: 401 })
        end
      end

      it "cannot set avatar state" do
        raw_api_call(:put, @path, @path_options, {
                       user: {
                         avatar: {
                           state: "locked"
                         }
                       }
                     })
        expect(response).to have_http_status :unauthorized
      end

      it "cannot see avatar_state" do
        raw_api_call(:put, "/api/v1/users/#{@user.id}", @path_options.merge(id: @user.id), { email: "test@example.com" })
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to_not have_key("avatar_state")
      end
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        @account0 = Account.default
        @cs_user = nil
        @shard1.activate do
          @account1 = account_model
          @account1.trust_links.create!(managing_account: @account0)
          @cs_user = User.create!
        end
        @cs_ps = managed_pseudonym(@cs_user, account: @account0, sis_user_id: "cross_shard_user")
        site_admin_user
      end

      it "set up the cross-shard pseudonym properly" do
        expect(@cs_ps.user_id).to eq @cs_user.global_id
      end

      it "updates a cross-shard user via global id" do
        json = api_call(:put,
                        "/api/v1/users/#{@cs_user.global_id}",
                        @path_options.merge(id: @cs_user.global_id.to_s),
                        { user: { name: "Santonio Holmes" } })

        expect(json["id"]).to eq @cs_user.global_id
        expect(json["name"]).to eq "Santonio Holmes"
        expect(@cs_ps.reload.user_id).to eq @cs_user.global_id
        expect(@cs_user.reload.name).to eq "Santonio Holmes"
      end

      it "updates a cross-shard user via sis_user_id (without breaking their pseudonym)" do
        json = api_call(:put,
                        "/api/v1/users/sis_user_id:cross_shard_user",
                        @path_options.merge(id: "sis_user_id:cross_shard_user"),
                        { user: { name: "Lavender Gooms" } })

        expect(json["id"]).to eq @cs_user.global_id
        expect(json["name"]).to eq "Lavender Gooms"
        expect(@cs_ps.reload.user_id).to eq @cs_user.global_id
        expect(@cs_user.reload.name).to eq "Lavender Gooms"
      end
    end

    context "an unauthorized user" do
      it "receives a 401" do
        user_factory
        raw_api_call(:put, @path, @path_options, {
                       user: { name: "Gob Bluth" }
                     })
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "user settings" do
    before :once do
      course_with_student(active_all: true)
      account_admin_user
    end

    let(:path) { "/api/v1/users/#{@student.to_param}/settings" }
    let(:path_options) do
      { controller: "users",
        action: "settings",
        format: "json",
        id: @student.to_param }
    end

    context "an admin user" do
      it "is able to view other users' settings" do
        @student.preferences[:collapse_global_nav] = true
        @student.save!
        json = api_call(:get, path, path_options)
        expect(json["manual_mark_as_read"]).to be false
        expect(json["collapse_global_nav"]).to be true
        expect(json["hide_dashcard_color_overlays"]).to be false
      end

      it "is able to update other users' settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true, hide_dashcard_color_overlays: false, comment_library_suggestions_enabled: true)
        expect(json["manual_mark_as_read"]).to be true
        expect(json["hide_dashcard_color_overlays"]).to be false
        expect(json["comment_library_suggestions_enabled"]).to be true

        json = api_call(:put, path, path_options, manual_mark_as_read: false, hide_dashcard_color_overlays: true, comment_library_suggestions_enabled: false)
        expect(json["manual_mark_as_read"]).to be false
        expect(json["hide_dashcard_color_overlays"]).to be true
        expect(json["comment_library_suggestions_enabled"]).to be false
      end
    end

    context "a student" do
      before do
        @user = @student
      end

      it "is able to view its own settings" do
        json = api_call(:get, path, path_options)
        expect(json["manual_mark_as_read"]).to be_falsey
      end

      it "is able to update its own settings" do
        json = api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(json["manual_mark_as_read"]).to be_truthy

        json = api_call(:put, path, path_options, manual_mark_as_read: false)
        expect(json["manual_mark_as_read"]).to be_falsey
      end

      it "receives 401 if updating another user's settings" do
        @course.enroll_student(user_factory).accept!
        raw_api_call(:put, path, path_options, manual_mark_as_read: true)
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "user custom_data" do
    let(:namespace_a) { "com.awesome-developer.mobile" }
    let(:namespace_b) { "org.charitable-developer.generosity" }
    let(:scope) { "nice/scope" }
    let(:scope2) { "something-different" }
    let(:path) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope}" }
    let(:path2) { "/api/v1/users/#{@student.to_param}/custom_data/#{scope2}" }
    let(:path_opts_put) do
      { controller: "custom_data",
        action: "set_data",
        format: "json",
        user_id: @student.to_param,
        scope: }
    end
    let(:path_opts_get) { path_opts_put.merge({ action: "get_data" }) }
    let(:path_opts_del) { path_opts_put.merge({ action: "delete_data" }) }
    let(:path_opts_put2) { path_opts_put.merge({ scope: scope2 }) }
    let(:path_opts_get2) { path_opts_put2.merge({ action: "get_data" }) }

    it "scopes storage by namespace and a *scope glob" do
      data = "boom shaka-laka"
      other_data = "whoop there it is"
      data2 = "whatevs"
      other_data2 = "totes"
      api_call(:put, path,  path_opts_put,  { ns: namespace_a, data: })
      api_call(:put, path2, path_opts_put2, { ns: namespace_a, data: data2 })
      api_call(:put, path,  path_opts_put,  { ns: namespace_b, data: other_data })
      api_call(:put, path2, path_opts_put2, { ns: namespace_b, data: other_data2 })

      body = api_call(:get, path, path_opts_get, { ns: namespace_a })
      expect(body).to eq({ "data" => data })

      body = api_call(:get, path, path_opts_get, { ns: namespace_b })
      expect(body).to eq({ "data" => other_data })

      body = api_call(:get, path2, path_opts_get2, { ns: namespace_a })
      expect(body).to eq({ "data" => data2 })

      body = api_call(:get, path2, path_opts_get2, { ns: namespace_b })
      expect(body).to eq({ "data" => other_data2 })
    end

    it "turns JSON hashes into scopes" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      get_path = path + "/b"
      get_scope = scope + "/b"
      api_call(:put, path, path_opts_put, { ns: namespace_a, data: })
      body = api_call(:get, get_path, path_opts_get.merge({ scope: get_scope }), { ns: namespace_a })
      expect(body).to eq({ "data" => "dont you think?" })
    end

    it "is deleteable" do
      data = JSON.parse '{"a":"nice JSON","b":"dont you think?"}'
      del_path = path + "/b"
      del_scope = scope + "/b"
      api_call(:put, path, path_opts_put, { ns: namespace_a, data: })
      body = api_call(:delete, del_path, path_opts_del.merge({ scope: del_scope }), { ns: namespace_a })
      expect(body).to eq({ "data" => "dont you think?" })

      body = api_call(:get, path, path_opts_get, { ns: namespace_a })
      expect(body).to eq({ "data" => { "a" => "nice JSON" } })
    end

    context "without a namespace" do
      it "responds 400 to GET" do
        api_call(:get, path, path_opts_get, {}, {}, { expected_status: 400 })
      end

      it "responds 400 to PUT" do
        api_call(:put, path, path_opts_put, { data: "whatevs" }, {}, { expected_status: 400 })
      end

      it "responds 400 to DELETE" do
        api_call(:delete, path, path_opts_del, {}, {}, { expected_status: 400 })
      end
    end

    context "PUT" do
      it "responds 409 when the requested scope is invalid" do
        deeper_path = path + "/whoa"
        deeper_scope = scope + "/whoa"
        api_call(:put, path, path_opts_put, { ns: namespace_a, data: "ohai!" })
        raw_api_call(:put, deeper_path, path_opts_put.merge({ scope: deeper_scope }), { ns: namespace_a, data: "dood" })
        expect(response).to have_http_status :conflict
      end
    end
  end

  describe "removing user from account" do
    before :once do
      @admin = account_admin_user
      course_with_student(user: user_with_pseudonym(name: "Student", username: "student@example.com"))
      @student = @user
      @user = @admin
      @path = "/api/v1/accounts/#{Account.default.id}/users/#{@student.id}"
      @path_options = { controller: "accounts",
                        action: "remove_user",
                        format: "json",
                        user_id: @student.to_param,
                        account_id: Account.default.to_param }
    end

    context "a user with permissions" do
      it "is able to delete a user" do
        Timecop.freeze do
          json = api_call(:delete, @path, @path_options)
          expect(@student.associated_accounts).not_to include(Account.default)
          expect(json.to_json).to eq @student.reload.to_json
        end
      end

      it "is able to delete a user by SIS ID" do
        @student.pseudonym.update_attribute(:sis_user_id, "12345")
        id_param = "sis_user_id:#{@student.pseudonyms.first.sis_user_id}"

        path = "/api/v1/accounts/#{Account.default.id}/users/#{id_param}"
        path_options = @path_options.merge(user_id: id_param)
        api_call(:delete, path, path_options)
        expect(response).to have_http_status :ok
        expect(@student.associated_accounts).not_to include(Account.default)
      end

      it "is able to delete itself" do
        Timecop.freeze do
          path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@user.id}"
          json = api_call(:delete, path, @path_options.merge(user_id: @user.to_param))
          expect(@user.associated_accounts).not_to include(Account.default)
          expect(json.to_json).to eq @user.reload.to_json
        end
      end
    end

    context "an unauthorized user" do
      it "receives a 401" do
        user_factory
        raw_api_call(:delete, @path, @path_options)
        expect(response).to have_http_status :unauthorized
      end
    end

    context "a non-admin user" do
      it "is not able to delete itself" do
        path = "/api/v1/accounts/#{Account.default.to_param}/users/#{@student.id}"
        api_call_as_user(@student, :delete, path, @path_options.merge(user_id: @student.to_param), {}, {}, expected_status: 401)
      end
    end
  end

  describe "DELETE expire_mobile_sessions" do
    let_once(:user) { user_with_pseudonym(active_all: true)  }
    let_once(:admin) { account_admin_user(active_all: true)  }
    let_once(:path) { "/api/v1/users/mobile_sessions" }
    let_once(:path_options) { { controller: "users", action: "expire_mobile_sessions", format: "json" } }

    before do
      user.access_tokens.create!
    end

    it "allows admin to expire mobile sessions" do
      user_session(admin)
      raw_api_call(:delete, path, path_options)

      expect(response).to have_http_status :ok
      expect(user.reload.access_tokens.take.permanent_expires_at).to be <= Time.zone.now
    end
  end

  context "user files" do
    before do
      @context = @user
    end

    include_examples "file uploads api with folders"
    include_examples "file uploads api with quotas"

    def preflight(preflight_params, opts = {})
      api_call(:post,
               "/api/v1/users/self/files",
               { controller: "users", action: "create_file", format: "json", user_id: "self", },
               preflight_params,
               {},
               opts)
    end

    def has_query_exemption?
      false
    end

    def context
      @user
    end

    it "does not allow uploading to other users" do
      user2 = User.create!
      api_call(:post,
               "/api/v1/users/#{user2.id}/files",
               { controller: "users", action: "create_file", format: "json", user_id: user2.to_param, },
               { name: "my_essay.doc" },
               {},
               expected_status: 401)
    end
  end

  describe "user merge and split" do
    before :once do
      @account = Account.default
      @user1 = user_with_managed_pseudonym(
        active_all: true,
        account: @account,
        name: "Jony Ive",
        username: "jony@apple.com",
        sis_user_id: "user_sis_id_01"
      )
      @user2 = user_with_managed_pseudonym(
        active_all: true,
        name: "Steve Jobs",
        account: @account,
        username: "steve@apple.com",
        sis_user_id: "user_sis_id_02"
      )
      @user = account_admin_user(account: @account)
    end

    it "merges and split users" do
      api_call(
        :put,
        "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        { controller: "users",
          action: "merge_into",
          format: "json",
          id: @user2.to_param,
          destination_user_id: @user1.to_param }
      )
      expect(Pseudonym.where(sis_user_id: "user_sis_id_02").first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
      api_call(
        :post,
        "/api/v1/users/#{@user1.id}/split/",
        { controller: "users", action: "split", format: "json", id: @user1.to_param }
      )
      expect(Pseudonym.where(sis_user_id: "user_sis_id_01").first.user_id).to eq @user1.id
      expect(Pseudonym.where(sis_user_id: "user_sis_id_02").first.user_id).to eq @user2.id
    end

    it "merges and split users cross accounts" do
      account = Account.create(name: "new account")
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!
      @user = account_admin_user(account:, user: @user)

      api_call(
        :put,
        "/api/v1/users/sis_user_id:user_sis_id_02/merge_into/accounts/#{account.id}/users/sis_user_id:user_sis_id_01",
        { controller: "users",
          action: "merge_into",
          format: "json",
          id: "sis_user_id:user_sis_id_02",
          destination_user_id: "sis_user_id:user_sis_id_01",
          destination_account_id: account.to_param }
      )
      expect(Pseudonym.where(sis_user_id: "user_sis_id_02").first.user_id).to eq @user1.id
      expect(@user2.pseudonyms).to be_empty
      api_call(
        :post,
        "/api/v1/users/#{@user1.id}/split/",
        { controller: "users", action: "split", format: "json", id: @user1.to_param }
      )
      expect(Pseudonym.where(sis_user_id: "user_sis_id_01").first.user_id).to eq @user1.id
      expect(Pseudonym.where(sis_user_id: "user_sis_id_02").first.user_id).to eq @user2.id
    end

    it "fails to merge users cross accounts without permissions" do
      account = Account.create(name: "new account")
      @user1.pseudonym.account_id = account.id
      @user1.pseudonym.save!

      raw_api_call(
        :put,
        "/api/v1/users/#{@user2.id}/merge_into/#{@user1.id}",
        { controller: "users",
          action: "merge_into",
          format: "json",
          id: @user2.to_param,
          destination_user_id: @user1.to_param }
      )
      assert_status(401)
    end

    it "fails to split users that have not been merged" do
      raw_api_call(:post,
                   "/api/v1/users/#{@user2.id}/split/",
                   { controller: "users", action: "split", format: "json", id: @user2.to_param })
      assert_status(400)
    end
  end

  describe "Custom Colors" do
    before do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe "GET custom colors" do
      before do
        @user.set_preference(:custom_colors, {
                               "user_#{@user.id}" => "efefef",
                               "course_3" => "ababab"
                             })
      end

      it "returns an empty object if nothing is stored" do
        @user.set_preference(:custom_colors, nil)

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors",
          { controller: "users",
            action: "get_custom_colors",
            format: "json",
            id: @user.to_param },
          { expected_status: 200 }
        )
        expect(json["custom_colors"].size).to eq 0
      end

      it "returns all custom colors for the user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors",
          { controller: "users",
            action: "get_custom_colors",
            format: "json",
            id: @user.to_param },
          { expected_status: 200 }
        )
        expect(json["custom_colors"].size).to eq 2
      end

      it "returns the color for a context when requested" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/colors/user_#{@user.id}",
          { controller: "users",
            action: "get_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "user_#{@user.id}" },
          { expected_status: 200 }
        )
        expect(json["hexcode"]).to eq "efefef"
      end
    end

    describe "PUT custom colors" do
      it "does not allow creating entries for entities that do not exist" do
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_999",
          { controller: "users",
            action: "set_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "course_999",
            hexcode: "ababab" },
          {},
          {},
          { expected_status: 404 }
        )
      end

      it "throws a bad request if a color isn't provided" do
        course_with_student(active_all: true)
        @user = @student
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: "users",
            action: "set_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "course_#{@course.id}" },
          {},
          {},
          { expected_status: 400 }
        )
      end

      it "throws a bad request if an invalid hexcode is provided" do
        course_with_student(active_all: true)
        @user = @student
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: "users",
            action: "set_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "course_#{@course.id}",
            hexcode: "yellow" },
          {},
          {},
          { expected_status: 400 }
        )
      end

      it "adds an entry for entities the user has access to" do
        course_with_student(active_all: true)
        @user = @student
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: "users",
            action: "set_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "course_#{@course.id}",
            hexcode: "ababab" },
          {},
          {},
          { expected_status: 200 }
        )
        expect(json["hexcode"]).to eq "#ababab"
      end

      it "emits user.set_custom_color to statsd" do
        course_with_student(active_all: true)
        allow(InstStatsd::Statsd).to receive(:increment)
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/colors/course_#{@course.id}",
          { controller: "users",
            action: "set_custom_color",
            format: "json",
            id: @user.to_param,
            asset_string: "course_#{@course.id}",
            hexcode: "ababab" },
          {},
          {},
          { expected_status: 200 }
        )
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("user.set_custom_color", tags: %w[enrollment_type:StudentEnrollment])
      end
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        course_factory(active_all: true)
        @cs_course = @course
        @shard1.activate do
          a = Account.create!
          @user = user_factory(account: a, active_all: true)
          @local_course = course_factory(active_all: true, account: a)
          @local_course.enroll_student(@user, enrollment_state: "active")
        end
        @cs_course.enroll_student(@user, enrollment_state: "active")
      end

      it "saves colors relative to user's shard" do
        @user.set_preference(:custom_colors, { "course_#{@local_course.local_id}" => "#bababa" })
        json = api_call(:put,
                        "/api/v1/users/#{@user.id}/colors/course_#{@cs_course.id}",
                        { controller: "users",
                          action: "set_custom_color",
                          format: "json",
                          id: @user.id.to_s,
                          asset_string: "course_#{@cs_course.id}",
                          hexcode: "ababab" },
                        {},
                        {},
                        { expected_status: 200 })
        expect(json["hexcode"]).to eq "#ababab"
        expect(@user.reload.get_preference(:custom_colors)["course_#{@cs_course.global_id}"]).to eq "#ababab"
        expect(@user.reload.get_preference(:custom_colors)["course_#{@local_course.local_id}"]).to eq "#bababa" # should leave existing colors alone
      end

      it "retrieves colors relative to user's shard" do
        @user.set_preference(:custom_colors, {
                               "course_#{@cs_course.global_id}" => "#ababab",
                               "course_#{@local_course.local_id}" => "#bababa",
                             })
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/colors",
                        { controller: "users", action: "get_custom_colors", format: "json", id: @user.id.to_s },
                        {},
                        {},
                        { expected_status: 200 })
        expect(json["custom_colors"]["course_#{@cs_course.local_id}"]).to eq "#ababab"
        expect(json["custom_colors"]["course_#{@local_course.global_id}"]).to eq "#bababa"
      end

      it "ignores old cross-shard data" do
        @user.set_preference(:custom_colors, {
                               "course_#{@local_course.global_id}" => "#ffffff", # old data plz ignore
                               "course_#{@local_course.local_id}" => "#ababab" # new data
                             })
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/colors",
                        { controller: "users", action: "get_custom_colors", format: "json", id: @user.id.to_s },
                        {},
                        {},
                        { expected_status: 200 })
        expect(json["custom_colors"]["course_#{@local_course.global_id}"]).to eq "#ababab"
      end
    end
  end

  describe "dashboard positions" do
    before do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe "GET dashboard positions" do
      before do
        @user.set_preference(:dashboard_positions, {
                               "course_1" => 3,
                               "course_2" => 1,
                               "course_3" => 2
                             })
      end

      it "returns dashboard postions for a user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "get_dashboard_positions",
            format: "json",
            id: @user.to_param },
          { expected_status: 200 }
        )
        expect(json["dashboard_positions"].size).to eq 3
      end

      it "returns an empty if the user has no ordering set" do
        @user.set_preference(:dashboard_positions, nil)

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "get_dashboard_positions",
            format: "json",
            id: @user.to_param },
          { expected_status: 200 }
        )
        expect(json["dashboard_positions"].size).to eq 0
      end
    end

    describe "PUT dashboard positions" do
      it "errors when trying to use a large number" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)

        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "set_dashboard_positions",
            format: "json",
            id: @user.to_param },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 2000,
              "course_#{course2.id}" => 13,
            }
          },
          {},
          { expected_status: 400 }
        )
        expect(json["message"]).to eq "Position 2000 is too high. Your dashboard cards can probably be sorted with numbers 1-5, you could even use a 0."
      end

      it "allows setting dashboard positions" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "set_dashboard_positions",
            format: "json",
            id: @user.to_param },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_#{course2.id}" => 1,
            }
          },
          {},
          { expected_status: 200 }
        )
        expected = {
          "course_#{course1.id}" => "3",
          "course_#{course2.id}" => "1",
        }
        expect(json["dashboard_positions"]).to eq expected
      end

      it "does not allow creating entries for entities that do not exist" do
        course1 = course_factory(active_all: true)
        course1.enroll_user(@user, "TeacherEnrollment").accept!
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "set_dashboard_positions",
            format: "json",
            id: @user.to_param },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_100001" => 1,
            }
          },
          {},
          { expected_status: 404 }
        )
      end

      it "does not allow creating entries for entities that the user doesn't have read access to" do
        course_with_student(active_all: true)
        course1 = @course
        course2 = course_factory

        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "set_dashboard_positions",
            format: "json",
            id: @user.to_param },
          {
            dashboard_positions: {
              "course_#{course1.id}" => 3,
              "course_#{course2.id}" => 1,
            }
          },
          {},
          { expected_status: 401 }
        )
      end

      it "does not allow setting positions to strings" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)

        api_call(
          :put,
          "/api/v1/users/#{@user.id}/dashboard_positions",
          { controller: "users",
            action: "set_dashboard_positions",
            format: "json",
            id: @user.to_param },
          {
            dashboard_positions: {
              "course_#{course1.id}" => "top",
              "course_#{course2.id}" => 1,
            }
          },
          {},
          { expected_status: 400 }
        )
      end
    end
  end

  describe "New User Tutorial Collapsed Status" do
    before :once do
      @a = Account.default
      @u = user_factory(active_all: true)
      @a.account_users.create!(user: @u)
    end

    describe "GET new user tutorial statuses" do
      before :once do
        @user.set_preference(:new_user_tutorial_statuses, {
                               "home" => true,
                               "modules" => false,
                             })
      end

      it "returns new user tutorial collapsed statuses for a user" do
        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses",
          { controller: "users",
            action: "get_new_user_tutorial_statuses",
            format: "json",
            id: @user.to_param }
        )
        expect(json).to eq({ "new_user_tutorial_statuses" => { "collapsed" => { "home" => true, "modules" => false } } })
      end

      it "returns empty if the user has no preference set" do
        @user.set_preference(:new_user_tutorial_statuses, nil)

        json = api_call(
          :get,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses",
          { controller: "users",
            action: "get_new_user_tutorial_statuses",
            format: "json",
            id: @user.to_param }
        )
        expect(json).to eq({ "new_user_tutorial_statuses" => { "collapsed" => {} } })
      end
    end

    describe "PUT new user tutorial status" do
      it "allows setting new user tutorial status" do
        page_name = "modules"
        json = api_call(
          :put,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses/#{page_name}",
          { controller: "users",
            action: "set_new_user_tutorial_status",
            format: "json",
            id: @user.to_param,
            page_name: },
          {
            collapsed: true
          },
          {}
        )
        expect(json["new_user_tutorial_statuses"]["collapsed"]["modules"]).to be true
      end

      it "rejects setting status for pages that are not whitelisted" do
        page_name = "some_random_page"
        api_call(
          :put,
          "/api/v1/users/#{@user.id}/new_user_tutorial_statuses/#{page_name}",
          { controller: "users",
            action: "set_new_user_tutorial_status",
            format: "json",
            id: @user.to_param,
            page_name: },
          {},
          {},
          { expected_status: 400 }
        )
      end
    end
  end

  describe "missing submissions" do
    before :once do
      course_with_student(active_all: true)
      @observer = user_factory(active_all: true, active_state: "active")
      add_linked_observer(@student, @observer)
      @user = @observer
      due_date = 2.days.ago
      2.times do
        @course.assignments.create!(due_at: due_date, workflow_state: "published", submission_types: "online_text_entry")
      end
      @path = "/api/v1/users/#{@student.id}/missing_submissions"
      @params = { controller: "users", action: "missing_submissions", user_id: @student.id, format: "json" }
    end

    it "returns unsubmitted assignments due in the past" do
      json = api_call(:get, @path, @params)
      expect(json.length).to be 2
    end

    it "returns assignments in order of the submission time for the user" do
      assign = @course.assignments.create!(due_at: 5.days.ago, workflow_state: "published", submission_types: "online_text_entry")
      create_adhoc_override_for_assignment(assign, @student, due_at: 3.days.ago)
      SubmissionLifecycleManager.recompute(assign)

      json = api_call(:get, @path, @params)
      expect(json[0]["id"]).to eq assign.id
    end

    it "paginates properly when multiple submissions have the same cached_due_date" do
      id1 = api_call(:get, @path, @params.merge(per_page: 1, page: 1))[0]["id"].to_i
      id2 = api_call(:get, @path, @params.merge(per_page: 1, page: 2))[0]["id"].to_i
      expect([id1, id2]).to eq @course.assignments.pluck(:id).sort
    end

    it "does not return locked assignments if filter is set to 'submittable'" do
      @course.assignments.create!(due_at: 3.days.ago,
                                  workflow_state: "published",
                                  submission_types: "online_text_entry",
                                  lock_at: 2.days.ago)
      json = api_call(:get, @path, @params)
      expect(json.length).to be 3

      submittable_json = api_call(:get, @path, @params.merge(filter: ["submittable"]))
      expect(submittable_json.length).to be 2
    end

    it "returns course information if requested" do
      @params["include"] = ["course"]
      json = api_call(:get, @path, @params)
      expect(json.first["course"]["name"]).to eq(@course.name)
    end

    it "filters results to the specified course_ids if requested" do
      @course2 = @course
      course_with_student(active_all: true, user: @student)
      @course.assignments.create!(due_at: 5.days.ago, workflow_state: "published", submission_types: "online_text_entry")

      @params["course_ids"] = [@course.id]
      json = api_call(:get, @path, @params)
      expect(json.length).to be 1
      expect(json.first["course_id"]).to eq(@course.id)
    end

    it "does not return submitted assignments due in the past" do
      @course.assignments.first.submit_homework @student, submission_type: "online_text_entry"
      json = api_call(:get, @path, @params)
      expect(json.length).to be 1
    end

    it "does not return assignments that don't expect a submission" do
      ungraded = @course.assignments.create! due_at: 2.days.from_now, workflow_state: "published", submission_types: "not_graded"
      json = api_call(:get, @path, @params)
      expect(json.pluck("id")).not_to include ungraded.id
    end

    it "shows assignments past their due dates because of overrides" do
      assignment_with_override(course: @course, due_at: 1.day.from_now, submission_types: ["online_text_entry"])
      @override.due_at_overridden = true
      @override.due_at = 1.day.ago
      @override.save!
      json = api_call(:get, @path, @params)
      expect(json.length).to eq 3
      expect(json.last["id"]).to eq @assignment.id
      expect(json.last["due_at"]).to eq @override.due_at.iso8601
    end

    it "does not show assignments past their due dates if the user is not assigned" do
      add_section("Section 1")
      differentiated_assignment(course: @course,
                                course_section: @course_section,
                                due_at: 1.day.ago,
                                submission_types: ["online_text_entry"],
                                only_visible_to_overrides: true)
      json = api_call(:get, @path, @params)
      expect(json.length).to eq 2
    end

    it "does not show deleted assignments" do
      a = @course.assignments.create!(due_at: 2.days.ago, workflow_state: "published", submission_types: "online_text_entry")
      a.destroy
      json = api_call(:get, @path, @params)
      expect(json.pluck("id")).not_to include a.id
    end

    it "does not show unpublished assignments" do
      a = @course.assignments.create!(due_at: 2.days.ago, workflow_state: "unpublished", submission_types: "online_text_entry")
      json = api_call(:get, @path, @params)
      expect(json.pluck("id")).not_to include a.id
    end

    context "current_grading_period filter" do
      before :once do
        term = Account.default.enrollment_terms.create!(start_at: 10.years.ago)
        course_factory(active_all: true, enrollment_term_id: term.id)
        @course.enroll_student(@student, enrollment_state: :active)

        period_group = Account.default.grading_period_groups.create!
        period_group.enrollment_terms << @course.enrollment_term
        now = Time.zone.now
        period_group.grading_periods.create!(
          title: "Closed Period",
          start_date: 5.months.ago(now),
          end_date: 2.months.ago(now),
          close_date: 2.months.ago(now)
        )
        period_group.grading_periods.create!(
          title: "Current Period",
          start_date: 2.months.ago(now),
          end_date: 2.months.from_now(now),
          close_date: 2.months.from_now(now)
        )

        @course.assignments.create!(
          name: "Assignment in closed period",
          workflow_state: "published",
          submission_types: "online_text_entry",
          due_at: 4.months.ago(now)
        )
        @course.assignments.create!(
          name: "Assignment in current period",
          workflow_state: "published",
          submission_types: "online_text_entry",
          due_at: 1.month.ago
        )
      end

      it "returns all missing submissions when not applied" do
        json = api_call(:get, @path, @params)
        expect(json.length).to be 4
      end

      it "returns only missing submissions in the current grading period when applied" do
        json = api_call(:get, @path, @params.merge(filter: ["current_grading_period"]))
        expect(json.length).to be 3
        json.each do |assignment|
          expect(assignment["name"]).not_to eq "Assignment in closed period"
        end
      end

      context "with sharding" do
        specs_require_sharding

        before :once do
          @shard2.activate do
            account = Account.create!
            term = account.enrollment_terms.create!(start_at: 10.years.ago)
            course_factory(active_all: true, account:, enrollment_term_id: term.id)
            @course.enroll_student(@student, enrollment_state: :active)

            period_group = account.grading_period_groups.create!
            period_group.enrollment_terms << @course.enrollment_term
            now = Time.zone.now
            period_group.grading_periods.create!(
              title: "Closed Period (Shard 2)",
              start_date: 5.months.ago(now),
              end_date: 2.months.ago(now),
              close_date: 2.months.ago(now)
            )
            period_group.grading_periods.create!(
              title: "Current Period (Shard 2)",
              start_date: 2.months.ago(now),
              end_date: 2.months.from_now(now),
              close_date: 2.months.from_now(now)
            )

            @course.assignments.create!(
              name: "Assignment in closed period (Shard 2)",
              workflow_state: "published",
              submission_types: "online_text_entry",
              due_at: 4.months.ago(now)
            )
            @course.assignments.create!(
              name: "Assignment in current period (Shard 2)",
              workflow_state: "published",
              submission_types: "online_text_entry",
              due_at: 1.month.ago
            )
          end
        end

        it "returns all assignments from multiple shards without filter" do
          json = api_call(:get, @path, @params)
          expect(json.length).to be 6
        end

        it "returns just the missing submissions from 2 shards" do
          json = api_call(:get, @path, @params.merge(filter: ["current_grading_period"]))
          expect(response).to be_successful
          expect(json.length).to be 4
          assignments = ["Assignment", "Assignment", "Assignment in current period", "Assignment in current period (Shard 2)"]
          expect(json.pluck("name").sort).to eq assignments.sort
        end
      end
    end

    context "as observer" do
      before :once do
        @observer = user_factory(active_all: true)
        @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
        @path = "/api/v1/users/#{@observer.id}/missing_submissions"
        @params = { controller: "users", action: "missing_submissions", user_id: @observer.id, format: "json" }
      end

      before do
        user_session(@observer)
      end

      it "renders unauthorized if course_ids is not passed" do
        api_call(:get, @path, @params.merge(observed_user_id: @student.id))
        assert_unauthorized
      end

      it "renders unauthorized if course_ids is empty" do
        api_call(:get, @path, @params.merge(observed_user_id: @student.id, course_ids: []))
        assert_unauthorized
      end

      it "returns missing assignments data for observed student" do
        json = api_call(:get, @path, @params.merge(observed_user_id: @student.id, course_ids: [@course.id]))
        expect(json.length).to be(2)
        expect(json[0]["course_id"]).to eq(@course.id)
        expect(json[1]["course_id"]).to eq(@course.id)
      end

      it "renders unauthorized if the observer's enrollment is deleted" do
        @observer.enrollments.first.destroy
        api_call(:get, @path, @params.merge(observed_user_id: @student.id, course_ids: [@course.id]))
        assert_unauthorized
      end

      it "renders unauthorized if the observer isn't observing the student in a passed course" do
        course1 = @course
        course2 = course_factory(active_all: true)
        course2.enroll_student(@student, enrollment_state: "active")
        course2.enroll_user(@observer, "ObserverEnrollment")
        api_call(:get, @path, @params.merge(observed_user_id: @student.id, course_ids: [course1.id, course2.id]))
        assert_unauthorized
      end

      it "returns missing assignments for all courses provided" do
        course1 = @course
        course2 = course_factory(active_all: true)
        course3 = course_factory(active_all: true)
        course2.assignments.create!(name: "A2", due_at: 3.days.ago, workflow_state: "published", submission_types: "online_text_entry")
        course3.assignments.create!(name: "A3", due_at: 3.days.ago, workflow_state: "published", submission_types: "online_text_entry")
        course2.enroll_student(@student, enrollment_state: "active")
        course3.enroll_student(@student, enrollment_state: "active")
        course2.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
        course3.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })

        json = api_call(:get, @path, @params.merge(observed_user_id: @student.id, course_ids: [course1.id, course2.id]))
        p json
        expect(json.length).to be(3)
        assignment_names = json.pluck("name")
        expect(assignment_names).to include("A2")
        expect(assignment_names).not_to include("A3")
      end
    end
  end

  describe "POST pandata_events_token" do
    let(:fake_url) { "https://example.com/pandata/events" }

    let(:fake_secrets) do
      {
        "ios_key" => "IOS_key",
        "ios_secret" => "LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1JSGJBZ0VCQkVFemZx\nZStiTjhEN2VRY0tKa3hHSlJpd0dqaHE0eXBsdFJ3aXNMUkx6ZXpBSmQ4QTlL\nRTdNY2YKbkorK0ptNGpwcjNUaFpybHRyN2dXQ2VJWWdvZDZPSmhzS0FIQmdV\ncmdRUUFJNkdCaVFPQmhnQUVBSmV5NCszeAp0UGlja2h1RFQ3QWFsTW1BWVdz\neU5IMnlEejRxRjhCamhHZzgwVkE2QWJPMHQ2YVE4TGQyaktMVEFrU1U5SFFW\nClkrMlVVeUp0Q3FTWEg4dVlBTEI0ZmFwbGhwVWNoQ1pSa3pMMXcrZzVDUUJY\nMlhFS25PdXJabU5ieEVSRzJneGoKb3hsbmxub0pwQjR5YUkvbWNpWkJOYlVz\nL0hTSGJtRzRFUFVxeVViQgotLS0tLUVORCBFQyBQUklWQVRFIEtFWS0tLS0t\nCg==\n",
        "android_key" => "ANDROID_key",
        "android_secret" => "surrendernoworpreparetofight"
      }.with_indifferent_access
    end

    before do
      allow(PandataEvents).to receive_messages(endpoint: fake_url, credentials: fake_secrets)
    end

    it "returns token and expiration" do
      Setting.set("pandata_events_token_allowed_developer_key_ids", DeveloperKey.default.global_id)
      json = api_call(:post,
                      "/api/v1/users/self/pandata_events_token",
                      { controller: "users", action: "pandata_events_token", format: "json", id: @user.to_param },
                      { app_key: "IOS_key" })
      expect(json["url"]).to be_present
      expect(json["auth_token"]).to be_present
      expect(json["props_token"]).to be_present
      expect(json["expires_at"]).to be_present

      public_key = OpenSSL::PKey::EC.new(<<~PEM)
        -----BEGIN PUBLIC KEY-----
        MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQAl7Lj7fG0+JySG4NPsBqUyYBhazI0
        fbIPPioXwGOEaDzRUDoBs7S3ppDwt3aMotMCRJT0dBVj7ZRTIm0KpJcfy5gAsHh9
        qmWGlRyEJlGTMvXD6DkJAFfZcQqc66tmY1vEREbaDGOjGWeWegmkHjJoj+ZyJkE1
        tSz8dIduYbgQ9SrJRsE=
        -----END PUBLIC KEY-----
      PEM
      body = Canvas::Security.decode_jwt(json["auth_token"], [public_key])
      expect(body[:iss]).to eq "IOS_key"
    end

    it "returns bad_request for incorrect app keys" do
      Setting.set("pandata_events_token_allowed_developer_key_ids", DeveloperKey.default.global_id)
      json = api_call(:post,
                      "/api/v1/users/self/pandata_events_token",
                      { controller: "users", action: "pandata_events_token", format: "json", id: @user.to_param },
                      { app_key: "IOS_not_right" })
      assert_status(400)
      expect(json["message"]).to eq "Invalid app key"
    end

    it "returns bad_request for app keys not in the prefix list" do
      Setting.set("pandata_events_token_allowed_developer_key_ids", DeveloperKey.default.global_id)
      Setting.set("pandata_events_token_prefixes", "android")
      json = api_call(:post,
                      "/api/v1/users/self/pandata_events_token",
                      { controller: "users", action: "pandata_events_token", format: "json", id: @user.to_param },
                      { app_key: "IOS_key" })
      assert_status(400)
      expect(json["message"]).to eq "Invalid app key"
    end

    it "returns forbidden if the tokens key is not authorized" do
      json = api_call(:post,
                      "/api/v1/users/self/pandata_events_token",
                      { controller: "users", action: "pandata_events_token", format: "json", id: @user.to_param },
                      { app_key: "IOS_key" })
      assert_status(403)
      expect(json["message"]).to eq "Developer key not authorized"
    end
  end

  describe "#user_graded_submissions" do
    specs_require_sharding

    before :once do
      teacher1 = course_with_teacher(active_all: true).user
      @course1 = @course
      @student1 = student_in_course(course: @course1, active_all: true).user
      @student1.associate_with_shard(@shard1)
      # We add another student we don't track as this brought out an error in the code when one of the tests was
      # triggered.
      student_in_course(course: @course1, active_all: true)
      @student2 = student_in_course(course: @course1).user

      @shard1.activate do
        cross_account = account_model(name: "crossshard", default_time_zone: "UTC")
        teacher2 = course_with_teacher(account: cross_account, active_all: true).user
        course2 = @course
        @course2_enrollment = course2.enroll_student(@student1)
        @course2_enrollment.accept!
        @assignment1 = assignment_model(course: course2, submission_types: "online_text_entry")
        @most_recent_submission = @assignment1.grade_student(@student1, grader: teacher2, score: 10).first
        @most_recent_submission.graded_at = 1.day.ago
        @most_recent_submission.save!
      end

      assignment = assignment_model(course: @course1, submission_types: "online_text_entry")
      @next_submission = assignment.grade_student(@student1, grader: teacher1, score: 10).first
      @next_submission.graded_at = 2.days.ago
      @next_submission.save!

      assignment = assignment_model(course: @course1, submission_types: "online_text_entry")
      @last_submission = assignment.grade_student(@student1, grader: teacher1, score: 10).first
      @last_submission.graded_at = 3.days.ago
      @last_submission.save!

      assignment = assignment_model(course: @course, submission_types: "online_text_entry")
      assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "done")
    end

    it "doesn't allow any user to get another user's submissions" do
      api_call_as_user(@student2, :get, "/api/v1/users/#{@student1.id}/graded_submissions", {
                         id: @student1.to_param,
                         controller: "users",
                         action: "user_graded_submissions",
                         format: "json"
                       })
      assert_status(401)
    end

    it "allows a user who can :read_grades to get a users submissions" do
      api_call_as_user(account_admin_user, :get, "/api/v1/users/#{@student1.id}/graded_submissions", {
                         id: @student1.to_param,
                         controller: "users",
                         action: "user_graded_submissions",
                         format: "json"
                       })
      assert_status(200)
    end

    it "gets the users submissions" do
      json = api_call_as_user(@student1, :get, "/api/v1/users/#{@student1.id}/graded_submissions", {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json"
                              })
      expect(json.count).to eq 3
      expect(json.pluck("id")).to eq [@most_recent_submission.id, @next_submission.id, @last_submission.id]
    end

    it "only gets the users submissions for active enrollments when only_current_enrollments=true" do
      @course2_enrollment.conclude
      json = api_call_as_user(@student1, :get, "/api/v1/users/#{@student1.id}/graded_submissions?only_current_enrollments=true", {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json",
                                only_current_enrollments: true
                              })
      expect(json.count).to eq 2
      expect(json.pluck("id")).to eq [@next_submission.id, @last_submission.id]
    end

    it "only gets the users submissions for published assignments when only_published_assignments=true" do
      # normally there should not be submissions for unpublished assignments
      # but there's an edge case with late policies
      # using update_column because we can't unpublish an assignment with submissions
      @assignment1.update_column(:workflow_state, "unpublished")
      json = api_call_as_user(@student1, :get, "/api/v1/users/#{@student1.id}/graded_submissions?only_published_assignments=true", {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json",
                                only_published_assignments: true,
                              })
      expect(json.count).to eq 2
      expect(json.pluck("id")).to eq [@next_submission.id, @last_submission.id]
    end

    it "paginates" do
      json = api_call_as_user(@student1, :get, "/api/v1/users/#{@student1.id}/graded_submissions?per_page=2", {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json",
                                per_page: 2
                              })
      expect(json.count).to eq 2

      response.headers["Link"].split(",").find { |l| l =~ /<([^>]+)>.+next/ }
      url = $1
      _, querystring = url.split("?")
      page = Rack::Utils.parse_nested_query(querystring)["page"]

      json = api_call_as_user(@student1, :get, url, {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json",
                                per_page: 2,
                                page:
                              })

      expect(json.count).to eq 1
    end

    it "will include the assignment when asked for" do
      json = api_call_as_user(@student1, :get, "/api/v1/users/#{@student1.id}/graded_submissions?include[]=assignment", {
                                id: @student1.to_param,
                                controller: "users",
                                action: "user_graded_submissions",
                                format: "json",
                                include: ["assignment"]
                              })
      expect(json.count).to eq 3
      expect(json[0]["assignment"]["id"]).to eq @most_recent_submission.assignment.id
    end
  end
end
