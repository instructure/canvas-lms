# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "LMGB User Details API", type: :request do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @section1 = @course.course_sections.first
    @section2 = @course.course_sections.create!(name: "Section 2")
    @course.enroll_student(@student, section: @section2, allow_multiple_enrollments: true).accept!
  end

  def lmgb_user_details_url(course, user)
    "/api/v1/courses/#{course.id}/users/#{user.id}/lmgb_user_details"
  end

  describe "authorization" do
    it "requires manage_grades permission for teachers" do
      @user = @teacher
      raw_api_call(:get,
                   lmgb_user_details_url(@course, @student),
                   controller: "lmgb_user_details",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @student.id.to_s)
      expect(response).to be_successful
    end

    it "allows students to read their own details" do
      @user = @student
      raw_api_call(:get,
                   lmgb_user_details_url(@course, @student),
                   controller: "lmgb_user_details",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @student.id.to_s)
      expect(response).to be_successful
    end

    it "does not allow students to read other users' details" do
      first_student = @student
      other_student = student_in_course(active_all: true).user
      @user = first_student
      raw_api_call(:get,
                   lmgb_user_details_url(@course, other_student),
                   controller: "lmgb_user_details",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: other_student.id.to_s)
      assert_forbidden
    end

    it "requires user to have view_all_grades permission" do
      other_teacher = teacher_in_course(active_all: true).user
      @course.account.role_overrides.create!(role: teacher_role, enabled: false, permission: :view_all_grades)
      @course.account.role_overrides.create!(role: teacher_role, enabled: false, permission: :manage_grades)

      @user = other_teacher
      raw_api_call(:get,
                   lmgb_user_details_url(@course, @student),
                   controller: "lmgb_user_details",
                   action: "show",
                   format: "json",
                   course_id: @course.id.to_s,
                   id: @student.id.to_s)
      assert_forbidden
    end
  end

  describe "response format" do
    before do
      @user = @teacher
      @student.pseudonyms.create!(unique_id: "test@example.com", account: @course.account)
      @student.pseudonyms.first.update!(last_login_at: Time.zone.parse("2024-06-01T12:00:00Z"))
    end

    it "returns course name" do
      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      expect(json["course"]["name"]).to eq(@course.name)
    end

    it "returns user sections" do
      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      sections = json["user"]["sections"]
      expect(sections.length).to eq(2)
      expect(sections.pluck("id")).to contain_exactly(@section1.id, @section2.id)
      expect(sections.pluck("name")).to contain_exactly(@section1.name, @section2.name)
    end

    it "returns user sections ordered alphabetically by name" do
      # Create sections with names that are not in alphabetical order
      section_charlie = @course.course_sections.create!(name: "Charlie")
      section_alpha = @course.course_sections.create!(name: "Alpha")
      section_bravo = @course.course_sections.create!(name: "Bravo")

      # Enroll student in all sections
      @course.enroll_student(@student, section: section_charlie, allow_multiple_enrollments: true).accept!
      @course.enroll_student(@student, section: section_alpha, allow_multiple_enrollments: true).accept!
      @course.enroll_student(@student, section: section_bravo, allow_multiple_enrollments: true).accept!

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      section_names = json["user"]["sections"].pluck("name")
      expect(section_names).to eq(section_names.sort)
    end

    it "includes sections with invited enrollments" do
      section_invited = @course.course_sections.create!(name: "Invited Section")
      # Create an invited (pending) enrollment without accepting it
      @course.enroll_student(@student, section: section_invited, allow_multiple_enrollments: true)

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      section_ids = json["user"]["sections"].pluck("id")
      expect(section_ids).to include(section_invited.id)
    end

    it "includes sections with completed enrollments" do
      section_completed = @course.course_sections.create!(name: "Completed Section")
      enrollment = @course.enroll_student(@student, section: section_completed, allow_multiple_enrollments: true)
      enrollment.conclude

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      section_ids = json["user"]["sections"].pluck("id")
      expect(section_ids).to include(section_completed.id)
    end

    it "includes sections with inactive enrollments" do
      section_inactive = @course.course_sections.create!(name: "Inactive Section")
      enrollment = @course.enroll_student(@student, section: section_inactive, allow_multiple_enrollments: true)
      enrollment.deactivate

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      section_ids = json["user"]["sections"].pluck("id")
      expect(section_ids).to include(section_inactive.id)
    end

    it "excludes sections with deleted enrollments" do
      section_deleted = @course.course_sections.create!(name: "Deleted Section")
      enrollment = @course.enroll_student(@student, section: section_deleted, allow_multiple_enrollments: true)
      enrollment.destroy

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      section_ids = json["user"]["sections"].pluck("id")
      expect(section_ids).not_to include(section_deleted.id)
    end

    it "returns user last login" do
      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      expect(json["user"]["last_login"]).to eq("2024-06-01T12:00:00Z")
    end

    it "returns null for last_login when user has never logged in" do
      @student.pseudonyms.first.update!(last_login_at: nil)

      json = api_call(:get,
                      lmgb_user_details_url(@course, @student),
                      controller: "lmgb_user_details",
                      action: "show",
                      format: "json",
                      course_id: @course.id.to_s,
                      id: @student.id.to_s)

      expect(json["user"]["last_login"]).to be_nil
    end
  end
end
