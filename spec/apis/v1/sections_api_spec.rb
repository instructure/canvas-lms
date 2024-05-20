# frozen_string_literal: true

#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

describe SectionsController, type: :request do
  describe "#index" do
    let(:user_api_fields) { %w[id name sortable_name short_name created_at] }

    before :once do
      course_with_teacher(active_all: true, user: user_with_pseudonym(name: "UWP"))
      @me = @user
      @course1 = @course
      course_with_student(user: @user, active_all: true)
      @course2 = @course
      @course2.update_attribute(:sis_source_id, "TEST-SIS-ONE.2011")
      @user.pseudonym.update_attribute(:sis_user_id, "user1")
    end

    it "returns the list of sections for a course" do
      user1 = @user
      user2 = User.create!(name: "Zombo")
      section1 = @course2.default_section
      section2 = @course2.course_sections.create!(name: "Section B")
      section2.update_attribute :sis_source_id, "sis-section"
      @course2.enroll_user(user2, "StudentEnrollment", section: section2).accept!
      RoleOverride.create!(context: Account.default, permission: "read_sis", role: teacher_role, enabled: false)

      @user = @me
      json = api_call(:get,
                      "/api/v1/courses/#{@course2.id}/sections.json",
                      { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" },
                      { include: ["students"] })
      expect(json.size).to eq 2
      expect(json.find { |s| s["name"] == section1.name }["students"]).to eq api_json_response([user1], only: user_api_fields)
      expect(json.find { |s| s["name"] == section2.name }["students"]).to eq api_json_response([user2], only: user_api_fields)
    end

    it "returns the list of enrollments if 'students' and 'enrollments' flags are given" do
      user1 = @user
      user2 = User.create!(name: "Zombo")
      section1 = @course2.default_section
      section2 = @course2.course_sections.create!(name: "Section B")
      @course2.enroll_user(user2, "StudentEnrollment", section: section2).accept!
      @user = @me

      json = api_call(:get,
                      "/api/v1/courses/#{@course2.id}/sections.json",
                      { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" },
                      { include: ["students", "enrollments"] })
      expect(json.size).to eq 2
      expect(json.find { |s| s["name"] == section1.name }["students"][0]["enrollments"][0]["user_id"]).to eq(user1.id)
      expect(json.find { |s| s["name"] == section2.name }["students"][0]["enrollments"][0]["user_id"]).to eq(user2.id)
    end

    it "returns the count of active and invited students if 'total_students' flag is given" do
      user2 = User.create!(name: "Bernard")
      user3 = User.create!(name: "Hoagie")
      user4 = User.create!(name: "Laverne")
      @course2.default_section
      section2 = @course2.course_sections.create!(name: "Section 31")

      @course2.enroll_user(user2, "StudentEnrollment", section: section2).accept!
      @course2.enroll_user(user3, "StudentEnrollment", section: section2).accept!
      @course2.enroll_user(user4, "StudentEnrollment", section: section2)

      @user = @me

      json = api_call(:get,
                      "/api/v1/courses/#{@course2.id}/sections.json",
                      { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" },
                      { include: "total_students" })

      hash = json.detect { |s| s["id"] == section2.id }
      expect(hash).to include("total_students")
      expect(hash["total_students"]).to eq 3
    end

    it "does not return deleted sections" do
      @course2.default_section
      section2 = @course2.course_sections.create!(name: "Section B")
      section2.destroy
      section2.save!
      json = api_call(:get,
                      "/api/v1/courses/#{@course2.id}/sections.json",
                      { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" },
                      { include: ["students"] })
      expect(json.size).to eq 1
    end

    it "respects ?per_page=n" do
      @course2.course_sections.create!(name: "Section B")
      @course2.course_sections.create!(name: "Section C")
      json = api_call(:get,
                      "/api/v1/courses/#{@course2.id}/sections.json",
                      { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" },
                      { per_page: 1 })
      expect(json.size).to eq 1
    end

    it "returns sections but not students if user has :read but not :read_roster, :view_all_grades, or :manage_grades" do
      RoleOverride.create!(context: Account.default, permission: "read_roster", role: ta_role, enabled: false)
      RoleOverride.create!(context: Account.default, permission: "view_all_grades", role: ta_role, enabled: false)
      RoleOverride.create!(context: Account.default, permission: "manage_grades", role: ta_role, enabled: false)
      enrollment = course_with_ta(active_all: true)
      enrollment.update_attribute(:limit_privileges_to_course_section, true)

      expect(@course.grants_right?(@ta, :read)).to be_truthy
      expect(@course.grants_right?(@ta, :read_roster)).to be_falsey
      expect(@course.grants_right?(@ta, :view_all_grades)).to be_falsey
      expect(@course.grants_right?(@ta, :manage_grades)).to be_falsey

      route_params = {
        controller: "sections",
        action: "index",
        course_id: @course.to_param,
        format: "json"
      }
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/sections.json",
                      route_params,
                      { include: ["students"] })

      expect(json.first["name"]).to eq @course.default_section.name
      expect(json.first.key?("students")).to be_falsey
    end

    it "returns all sections if :all are specified" do
      12.times { |i| @course2.course_sections.create!(name: "Section #{i}") }

      endpoint = "/api/v1/courses/#{@course2.id}/sections.json"
      params = { controller: "sections", action: "index", course_id: @course2.to_param, format: "json" }

      json = api_call(:get, endpoint, params, {})
      expect(json.size).to eq 10

      params[:all] = true
      json = api_call(:get, endpoint, params, {})
      expect(json.size).to eq @course2.course_sections.count
    end

    it "returns only sections matching the search term if provided" do
      @course1.course_sections.create!(name: "Normal Section 1")
      @course1.course_sections.create!(name: "Normal Section 2")
      @course1.course_sections.create!(name: "Advanced Section 1")
      @course1.course_sections.create!(name: "Advanced Section 2")

      json = api_call(:get,
                      "/api/v1/courses/#{@course1.id}/sections?search_term=normal",
                      { controller: "sections", action: "index", course_id: @course1.id, search_term: "normal", format: "json" })
      expect(json.length).to eq 2
      expect(json.pluck("name")).to match_array(["Normal Section 1", "Normal Section 2"])
    end

    it "returns permissions if specified" do
      section1 = @course1.default_section
      section2 = @course1.course_sections.create!(name: "Section 2")
      enrollment = @user.enrollments.active.where(course: @course1).first
      enrollment.limit_privileges_to_course_section = true
      enrollment.save!

      json = api_call(:get,
                      "/api/v1/courses/#{@course1.id}/sections",
                      { controller: "sections", action: "index", course_id: @course1.id, format: "json" },
                      { include: "permissions" })
      expect(json.length).to eq 2
      section1_json = json.detect { |s| s["id"] == section1.id }
      section2_json = json.detect { |s| s["id"] == section2.id }
      expect(section1_json["permissions"]["manage_calendar"]).to be_truthy
      expect(section2_json["permissions"]["manage_calendar"]).to be_falsey
    end
  end

  describe "#show" do
    before :once do
      course_with_teacher
      @section = @course.default_section
    end

    context "scoped by course" do
      before do
        @path_prefix = "/api/v1/courses/#{@course.id}/sections"
        @path_params = { controller: "sections", action: "show", course_id: @course.to_param, format: "json" }
      end

      it "is accessible from the course" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ id: @section.to_param }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "integration_id" => nil,
                             "sis_course_id" => nil,
                             "sis_section_id" => nil,
                             "created_at" => @section.created_at.iso8601
                           })
      end

      it "returns the count of active and invited students if 'total_students' flag is given" do
        @course.offer!
        user2 = User.create!(name: "Bernard")
        @course.enroll_user(user2, "StudentEnrollment", section: @section).accept!

        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ id: @section.to_param, include: ["total_students"] }))
        expect(json["total_students"]).to eq 1
      end

      it "does not include test students" do
        @course.student_view_student
        expect(@course.default_section.students.count).to eq 1
        expect(@course.default_section.students.not_fake_student.count).to eq 0
        json = api_call(:get,
                        "#{@path_prefix}/#{@course.default_section.id}",
                        @path_params.merge({ id: @course.default_section.to_param, include: ["total_students"] }))
        expect(json["total_students"]).to eq 0
      end

      it "is accessible from the course context via sis id" do
        @section.update_attribute(:sis_source_id, "my_section")
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ id: "sis_section_id:my_section" }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "integration_id" => nil,
                             "sis_course_id" => nil,
                             "sis_section_id" => "my_section",
                             "created_at" => @section.created_at.iso8601
                           })
      end

      it "scopes course sections to the course" do
        @other_course = course_factory
        @other_section = @other_course.default_section
        site_admin_user
        api_call(:get, "#{@path_prefix}/#{@other_section.id}", @path_params.merge({ id: @other_section.to_param }), {}, {}, expected_status: 404)
      end
    end

    context "unscoped" do
      before do
        @path_prefix = "/api/v1/sections"
        @path_params = { controller: "sections", action: "show", format: "json" }
      end

      it "is accessible without a course context" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ id: @section.to_param }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "integration_id" => nil,
                             "sis_course_id" => nil,
                             "sis_section_id" => nil,
                             "created_at" => @section.created_at.iso8601
                           })
      end

      it "is accessible without a course context via sis id" do
        @section.update_attribute(:sis_source_id, "my_section")
        json = api_call(:get, "#{@path_prefix}/sis_section_id:my_section", @path_params.merge({ id: "sis_section_id:my_section" }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "integration_id" => nil,
                             "sis_course_id" => nil,
                             "sis_section_id" => "my_section",
                             "created_at" => @section.created_at.iso8601
                           })
      end

      it "is accessible without a course context via integration id" do
        @section.update_attribute(:integration_id, "my_section")
        json = api_call(:get, "#{@path_prefix}/sis_integration_id:my_section", @path_params.merge({ id: "sis_integration_id:my_section" }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "integration_id" => "my_section",
                             "sis_course_id" => nil,
                             "sis_section_id" => nil,
                             "created_at" => @section.created_at.iso8601
                           })
      end

      it "is not accessible if the associated course is not accessible" do
        @course.destroy
        api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ id: @section.to_param }), {}, {}, expected_status: 404)
      end
    end

    context "as an admin" do
      before :once do
        site_admin_user
        @section = @course.default_section
        @path_prefix = "/api/v1/courses/#{@course.id}/sections"
        @path_params = { controller: "sections", action: "show", course_id: @course.to_param, format: "json" }
      end

      it "shows sis information" do
        json = api_call(:get, "#{@path_prefix}/#{@section.id}", @path_params.merge({ id: @section.to_param }))
        expect(json).to eq({
                             "id" => @section.id,
                             "name" => @section.name,
                             "course_id" => @course.id,
                             "sis_course_id" => @course.sis_source_id,
                             "sis_section_id" => @section.sis_source_id,
                             "sis_import_id" => @section.sis_batch_id,
                             "integration_id" => nil,
                             "nonxlist_course_id" => nil,
                             "start_at" => nil,
                             "end_at" => nil,
                             "restrict_enrollments_to_section_dates" => nil,
                             "created_at" => @section.created_at.iso8601
                           })
      end
    end
  end

  describe "#create" do
    before :once do
      course_factory
      @path_prefix = "/api/v1/courses/#{@course.id}/sections"
      @path_params = { controller: "sections", action: "create", course_id: @course.to_param, format: "json" }
    end

    context "as teacher" do
      before do
        course_with_teacher course: @course
      end

      it "creates a section with default parameters" do
        json = api_call(:post, @path_prefix, @path_params)
        @course.reload
        expect(@course.active_course_sections.where(id: json["id"].to_i)).to be_exists
      end

      it "finds the course by SIS ID" do
        @course.update_attribute :sis_source_id, "SISCOURSE"
        json = api_call(:post,
                        "/api/v1/courses/sis_course_id:SISCOURSE/sections",
                        { controller: "sections", action: "create", course_id: "sis_course_id:SISCOURSE", format: "json" })
        @course.reload
        expect(@course.active_course_sections.where(id: json["id"].to_i)).to be_exists
      end

      it "creates a section with custom parameters" do
        json = api_call(:post, @path_prefix, @path_params, { course_section: { name: "Name", start_at: "2011-01-01T01:00Z", end_at: "2011-07-01T01:00Z" } })
        @course.reload
        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.name).to eq "Name"
        expect(section.sis_source_id).to be_nil
        expect(section.start_at).to eq Time.parse("2011-01-01T01:00Z")
        expect(section.end_at).to eq Time.parse("2011-07-01T01:00Z")
      end

      it "fails if the context is deleted" do
        @course.destroy
        api_call(:post, @path_prefix, @path_params, {}, {}, expected_status: 404)
      end

      it "ignores the sis source id parameter" do
        json = api_call(:post, @path_prefix, @path_params, { course_section: { name: "Name", start_at: "2011-01-01T01:00Z", end_at: "2011-07-01T01:00Z", sis_section_id: "fail" } })
        @course.reload
        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.name).to eq "Name"
        expect(section.sis_source_id).to be_nil
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in(course: @course)
      end

      it "disallows creating a section" do
        api_call(:post, @path_prefix, @path_params, {}, {}, expected_status: 401)
      end
    end

    context "as admin" do
      before do
        site_admin_user
      end

      it "sets the sis source id and integration_id" do
        section_params = { name: "Name", sis_section_id: "fail", integration_id: "int1" }
        json = api_call(:post, @path_prefix, @path_params, { course_section: section_params })
        @course.reload
        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.name).to eq "Name"
        expect(section.sis_source_id).to eq "fail"
        expect(section.integration_id).to eq "int1"
        expect(section.sis_batch_id).to be_nil
      end

      it "sets the integration_id by itself" do
        section_params = { name: "Name", integration_id: "int1" }
        json = api_call(:post, @path_prefix, @path_params, { course_section: section_params })
        @course.reload
        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.name).to eq "Name"
        expect(section.integration_id).to eq "int1"
      end

      it "allows reactivating deleting sections using sis_section_id" do
        old_section = @course.course_sections.create!
        old_section.sis_source_id = "fail"
        old_section.save!
        old_section.destroy

        json = api_call(:post, @path_prefix, @path_params, { course_section: { name: "Name",
                                                                               start_at: "2011-01-01T01:00Z",
                                                                               end_at: "2011-07-01T01:00Z",
                                                                               sis_section_id: "fail" },
                                                             enable_sis_reactivation: "1" })

        expect(old_section).to eq @course.active_course_sections.find(json["id"].to_i)
        old_section.reload
        expect(old_section).to be_active
        expect(old_section.sis_source_id).to eq "fail"
      end

      it "raises an error trying to reactivate an active section" do
        old_section = @course.course_sections.create!
        old_section.sis_source_id = "fail"
        old_section.save!

        api_call(:post,
                 @path_prefix,
                 @path_params,
                 { course_section: { name: "Name",
                                     start_at: "2011-01-01T01:00Z",
                                     end_at: "2011-07-01T01:00Z",
                                     sis_section_id: "fail" },
                   enable_sis_reactivation: "1" },
                 {},
                 { expected_status: 400 })
      end

      it "carries on if there's no section to reactivate" do
        json = api_call(:post, @path_prefix, @path_params, { course_section: { name: "Name",
                                                                               start_at: "2011-01-01T01:00Z",
                                                                               end_at: "2011-07-01T01:00Z",
                                                                               sis_section_id: "fail" },
                                                             enable_sis_reactivation: "1" })

        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.sis_source_id).to eq "fail"
      end
    end

    context "as teacher having manage_sections_add permission" do
      before do
        course_with_teacher course: @course
      end

      it "creates a section with default parameters" do
        json = api_call(:post, @path_prefix, @path_params)
        @course.reload
        expect(@course.active_course_sections.where(id: json["id"].to_i)).to be_exists
      end

      it "creates a section with custom parameters" do
        json = api_call(:post, @path_prefix, @path_params, { course_section: { name: "Name", start_at: "2011-01-01T01:00Z", end_at: "2011-07-01T01:00Z" } })
        @course.reload
        section = @course.active_course_sections.find(json["id"].to_i)
        expect(section.name).to eq "Name"
        expect(section.sis_source_id).to be_nil
        expect(section.start_at).to eq Time.parse("2011-01-01T01:00Z")
        expect(section.end_at).to eq Time.parse("2011-07-01T01:00Z")
      end
    end

    context "as teacher without manage_sections_add permission" do
      before do
        course_with_teacher course: @course
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_sections_add",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows creating a section" do
        api_call(:post, @path_prefix, @path_params, {}, {}, expected_status: 401)
      end
    end
  end

  describe "#update" do
    before :once do
      course_factory
      @section = @course.course_sections.create! name: "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { controller: "sections", action: "update", format: "json" }
    end

    context "as teacher" do
      before :once do
        course_with_teacher course: @course
      end

      it "modifies section data by id" do
        json = api_call(:put, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z", restrict_enrollments_to_section_dates: "1" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.sis_source_id).to eq "SISsy"
        expect(@section.start_at).to eq Time.parse("2012-01-01T01:00Z")
        expect(@section.end_at).to eq Time.parse("2012-07-01T01:00Z")
        expect(@section.restrict_enrollments_to_section_dates).to be_truthy
      end

      it "modifies section data by sis id" do
        json = api_call(:put, "#{@path_prefix}/sis_section_id:SISsy", @path_params.merge(id: "sis_section_id:SISsy"), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.sis_source_id).to eq "SISsy"
        expect(@section.start_at).to eq Time.parse("2012-01-01T01:00Z")
        expect(@section.end_at).to eq Time.parse("2012-07-01T01:00Z")
      end

      it "behaves gracefully if the course_section parameter is missing" do
        json = api_call(:put, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param))
        expect(json["id"]).to eq @section.id
      end

      it "does not update sis sticky fields if override_sis_stickiness set to false" do
        json = api_call(:put, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z", restrict_enrollments_to_section_dates: "1" }, override_sis_stickiness: false })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "Test Section"
        expect(@section.sis_source_id).to eq "SISsy"
        expect(@section.start_at).to be_nil
        expect(@section.end_at).to be_nil
        expect(@section.restrict_enrollments_to_section_dates).to be_truthy
      end

      it "fails if the section is deleted" do
        @section.destroy
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { name: "New Name" } },
                 {},
                 expected_status: 404)
      end

      it "fails if the context is deleted" do
        @course.destroy
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { name: "New Name" } },
                 {},
                 expected_status: 404)
      end

      it "returns unauthorized when changing sis attributes" do
        json = api_call(:put,
                        "#{@path_prefix}/#{@section.id}",
                        @path_params.merge(id: @section.to_param),
                        { course_section: { name: "New Name", sis_section_id: "NEWSIS" } },
                        {},
                        expected_status: 401)
        expect(json["message"]).to eq "You must have manage_sis permission to update sis attributes"
        expect(@section.reload.sis_source_id).to eq "SISsy"
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in(course: @course)
      end

      it "disallows modifying a section" do
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { name: "New Name" } },
                 {},
                 expected_status: 401)
      end
    end

    context "as admin" do
      before do
        site_admin_user
      end

      it "sets integration_id" do
        json = api_call(:put,
                        "#{@path_prefix}/#{@section.id}",
                        @path_params.merge(id: @section.to_param),
                        { course_section: { name: "New Name", sis_section_id: "NEWSIS", integration_id: "int_id1" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.integration_id).to eq "int_id1"
        expect(@section.sis_source_id).to eq "NEWSIS"
      end

      it "does not change sis attributes when not passed" do
        CourseSection.where(id: @section).update_all(integration_id: "int_id_OG")
        json = api_call(:put,
                        "#{@path_prefix}/#{@section.id}",
                        @path_params.merge(id: @section.to_param),
                        { course_section: { name: "New Name", integration_id: "int1" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.integration_id).to eq "int1"
        expect(@section.sis_source_id).to eq "SISsy"
      end

      it "sets the sis id" do
        json = api_call(:put, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z", sis_section_id: "NEWSIS" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.sis_source_id).to eq "NEWSIS"
      end

      it "throws error when integration_id is not unique" do
        @course.course_sections.create!(name: "Test Section", integration_id: "taken")
        CourseSection.where(id: @section)
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { integration_id: "taken" } })
        expect(response).to be_bad_request
      end

      it "throws error when sis_id is not unique" do
        @course.course_sections.create!(name: "Test Section", sis_source_id: "taken")
        CourseSection.where(id: @section)
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { sis_section_id: "taken" } })
        expect(response).to be_bad_request
      end
    end

    context "as teacher having manage_sections_edit permission" do
      before do
        course_with_teacher course: @course
      end

      it "modifies section data by id" do
        json = api_call(:put, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z", restrict_enrollments_to_section_dates: "1" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.sis_source_id).to eq "SISsy"
        expect(@section.start_at).to eq Time.parse("2012-01-01T01:00Z")
        expect(@section.end_at).to eq Time.parse("2012-07-01T01:00Z")
        expect(@section.restrict_enrollments_to_section_dates).to be_truthy
      end

      it "modifies section data by sis id" do
        json = api_call(:put, "#{@path_prefix}/sis_section_id:SISsy", @path_params.merge(id: "sis_section_id:SISsy"), { course_section: { name: "New Name", start_at: "2012-01-01T01:00Z", end_at: "2012-07-01T01:00Z" } })
        expect(json["id"]).to eq @section.id
        @section.reload
        expect(@section.name).to eq "New Name"
        expect(@section.sis_source_id).to eq "SISsy"
        expect(@section.start_at).to eq Time.parse("2012-01-01T01:00Z")
        expect(@section.end_at).to eq Time.parse("2012-07-01T01:00Z")
      end
    end

    context "as teacher without manage_sections_edit permission" do
      before do
        course_with_teacher course: @course
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_sections_edit",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows modifying a section" do
        api_call(:put,
                 "#{@path_prefix}/#{@section.id}",
                 @path_params.merge(id: @section.to_param),
                 { course_section: { name: "New Name" } },
                 {},
                 expected_status: 401)
      end
    end
  end

  describe "#delete" do
    before :once do
      course_factory
      @section = @course.course_sections.create! name: "Test Section"
      @section.update_attribute(:sis_source_id, "SISsy")
      @path_prefix = "/api/v1/sections"
      @path_params = { controller: "sections", action: "destroy", format: "json" }
    end

    context "as teacher" do
      before :once do
        course_with_teacher course: @course
      end

      it "deletes a section by id" do
        json = api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param))
        expect(json["id"]).to eq @section.id
        expect(@section.reload).to be_deleted
      end

      it "deletes a section by sis id" do
        json = api_call(:delete, "#{@path_prefix}/sis_section_id:SISsy", @path_params.merge(id: "sis_section_id:SISsy"))
        expect(json["id"]).to eq @section.id
        expect(@section.reload).to be_deleted
      end

      it "fails to delete a section with enrollments" do
        @section.enroll_user(user_model, "StudentEnrollment", "active")
        @user = @teacher
        api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), {}, {}, expected_status: 400)
      end

      it "fails if the section is deleted" do
        @section.destroy
        api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), {}, {}, expected_status: 404)
      end

      it "fails if the context is deleted" do
        @course.destroy
        api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), {}, {}, expected_status: 404)
      end
    end

    context "as student" do
      before do
        course_with_student_logged_in course: @course
      end

      it "disallows deleting a section" do
        api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), {}, {}, expected_status: 401)
      end
    end

    context "as teacher having manage_sections_edit permission" do
      before do
        course_with_teacher course: @course
      end

      it "deletes a section by id" do
        json = api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param))
        expect(json["id"]).to eq @section.id
        expect(@section.reload).to be_deleted
      end

      it "deletes a section by sis id" do
        json = api_call(:delete, "#{@path_prefix}/sis_section_id:SISsy", @path_params.merge(id: "sis_section_id:SISsy"))
        expect(json["id"]).to eq @section.id
        expect(@section.reload).to be_deleted
      end
    end

    context "as teacher without manage_sections_delete permission" do
      before do
        course_with_teacher course: @course
        teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: @course.root_account.id)
        RoleOverride.create!(
          permission: "manage_sections_delete",
          enabled: false,
          role: teacher_role,
          account: @course.root_account
        )
      end

      it "disallows deleting a section" do
        api_call(:delete, "#{@path_prefix}/#{@section.id}", @path_params.merge(id: @section.to_param), {}, {}, expected_status: 401)
      end
    end
  end

  describe "#crosslist" do
    before :once do
      @dest_course = course_factory
      course_factory
      @section = @course.course_sections.create!
      @params = { controller: "sections", action: "crosslist", format: "json" }
    end

    context "as admin" do
      before :once do
        site_admin_user
      end

      it "cross-lists a section" do
        expect(@course.active_course_sections).to include(@section)
        expect(@dest_course.active_course_sections).not_to include(@section)

        json = api_call(:post,
                        "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                        @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @dest_course.id
        expect(json["nonxlist_course_id"]).to eq @course.id

        expect(@course.reload.active_course_sections).not_to include(@section)
        expect(@dest_course.reload.active_course_sections).to include(@section)
      end

      it "doesn't cross-lists a section if override_sis_stickiness set to false" do
        expect(@course.active_course_sections).to include(@section)
        expect(@dest_course.active_course_sections).not_to include(@section)

        json = api_call(:post,
                        "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                        @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param, override_sis_stickiness: false))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @course.id
        expect(json["nonxlist_course_id"]).to be_nil

        expect(@course.reload.active_course_sections).to include(@section)
        expect(@dest_course.reload.active_course_sections).not_to include(@section)
      end

      it "works with sis IDs" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")
        @sis_batch = @section.root_account.sis_batches.create
        SisBatch.where(id: @sis_batch).update_all(workflow_state: "imported")
        @section.sis_batch_id = @sis_batch.id
        @section.save!

        expect(@course.active_course_sections).to include(@section)
        expect(@dest_course.active_course_sections).not_to include(@section)

        json = api_call(:post,
                        "/api/v1/sections/sis_section_id:the_section/crosslist/sis_course_id:dest_course",
                        @params.merge(id: "sis_section_id:the_section", new_course_id: "sis_course_id:dest_course"))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @dest_course.id
        expect(json["nonxlist_course_id"]).to eq @course.id
        expect(json["sis_import_id"]).to eq @sis_batch.id

        expect(@course.reload.active_course_sections).not_to include(@section)
        expect(@dest_course.reload.active_course_sections).to include(@section)
      end

      it "fails if the section is deleted" do
        @section.destroy
        api_call(:post,
                 "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param),
                 {},
                 {},
                 expected_status: 404)
      end

      it "fails if the destination course is deleted" do
        @dest_course.destroy
        api_call(:post,
                 "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param),
                 {},
                 {},
                 expected_status: 404)
      end

      it "fails if the destination course is a blueprint" do
        MasterCourses::MasterTemplate.set_as_master_course(@dest_course)
        json = api_call(:post,
                        "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                        @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param),
                        {},
                        {},
                        expected_status: 403)
        expect(json["error"]).to eq "cannot crosslist into blueprint courses"
      end

      it "fails if the destination course is under a different root account" do
        foreign_account = Account.create!
        foreign_course = foreign_account.courses.create!
        api_call(:post,
                 "/api/v1/sections/#{@section.id}/crosslist/#{foreign_course.id}",
                 @params.merge(id: @section.to_param, new_course_id: foreign_course.to_param),
                 {},
                 {},
                 expected_status: 404)
      end

      it "confirms crosslist by sis id" do
        @dest_course.update_attribute(:sis_source_id, "blargh")
        user_session(@admin)
        json = api_call(:get,
                        "/courses/#{@course.id}/sections/#{@section.id}/crosslist/confirm/#{@dest_course.sis_source_id}",
                        @params.merge(action: "crosslist_check", course_id: @course.to_param, section_id: @section.to_param, new_course_id: @dest_course.sis_source_id))
        expect(json["course"]["id"]).to eql @dest_course.id
      end

      it "does not confirm crosslisting if the destination course is a blueprint" do
        MasterCourses::MasterTemplate.set_as_master_course(@dest_course)
        user_session(@admin)
        json = api_call(:get,
                        "/courses/#{@course.id}/sections/#{@section.id}/crosslist/confirm/#{@dest_course.id}",
                        @params.merge(action: "crosslist_check", course_id: @course.to_param, section_id: @section.to_param, new_course_id: @dest_course.id))
        expect(json["allowed"]).to be false
      end

      it "does not confirm crosslisting when the caller lacks :manage rights on the destination course" do
        @course.root_account.disable_feature!(:granular_permissions_manage_courses)
        account_admin =
          account_admin_user_with_role_changes(
            account: @course.root_account,
            role_changes: {
              manage_courses: false
            }
          )
        user_session(account_admin)
        json =
          api_call(
            :get,
            "/courses/#{@course.id}/sections/#{@section.id}/crosslist/confirm/#{@dest_course.id}",
            @params.merge(
              action: "crosslist_check",
              course_id: @course.to_param,
              section_id: @section.to_param,
              new_course_id: @dest_course.id
            )
          )
        expect(json["allowed"]).to be false
      end

      it "does not confirm crosslisting when the caller lacks :manage rights on the destination course (granular permissions)" do
        @course.root_account.enable_feature!(:granular_permissions_manage_courses)
        account_admin =
          account_admin_user_with_role_changes(
            account: @course.root_account,
            role_changes: {
              manage_courses_admin: false
            }
          )
        user_session(account_admin)
        json =
          api_call(
            :get,
            "/courses/#{@course.id}/sections/#{@section.id}/crosslist/confirm/#{@dest_course.id}",
            @params.merge(
              action: "crosslist_check",
              course_id: @course.to_param,
              section_id: @section.to_param,
              new_course_id: @dest_course.id
            )
          )
        expect(json["allowed"]).to be false
      end
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in course: @course
      end

      it "disallows cross-listing a section" do
        api_call(:post,
                 "/api/v1/sections/#{@section.id}/crosslist/#{@dest_course.id}",
                 @params.merge(id: @section.to_param, new_course_id: @dest_course.to_param),
                 {},
                 {},
                 expected_status: 401)
      end
    end
  end

  describe "#uncrosslist" do
    before :once do
      @dest_course = course_factory
      course_factory
      @section = @course.course_sections.create!
      @section.crosslist_to_course(@dest_course)
      @params = { controller: "sections", action: "uncrosslist", format: "json" }
    end

    context "as admin" do
      before :once do
        site_admin_user
      end

      it "un-crosslists a section" do
        expect(@course.active_course_sections).not_to include @section
        expect(@dest_course.active_course_sections).to include @section

        json = api_call(:delete,
                        "/api/v1/sections/#{@section.id}/crosslist",
                        @params.merge(id: @section.to_param))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @course.id
        expect(json["nonxlist_course_id"]).to be_nil

        expect(@course.reload.active_course_sections).to include @section
        expect(@dest_course.reload.active_course_sections).not_to include @section
      end

      it "doesn't remove course_id" do
        json = api_call(:delete,
                        "/api/v1/sections/#{@section.id}/crosslist",
                        @params.merge(id: @section.to_param, override_sis_stickiness: false))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @section.course_id
        expect(json["nonxlist_course_id"]).not_to be_nil

        expect(@course.reload.active_course_sections).not_to include @section
        expect(@dest_course.reload.active_course_sections).to include @section
      end

      it "works by SIS ID" do
        @dest_course.update_attribute(:sis_source_id, "dest_course")
        @section.update_attribute(:sis_source_id, "the_section")

        expect(@course.active_course_sections).not_to include @section
        expect(@dest_course.active_course_sections).to include @section

        json = api_call(:delete,
                        "/api/v1/sections/sis_section_id:the_section/crosslist",
                        @params.merge(id: "sis_section_id:the_section"))
        expect(json["id"]).to eq @section.id
        expect(json["course_id"]).to eq @course.id
        expect(json["nonxlist_course_id"]).to be_nil

        expect(@course.reload.active_course_sections).to include @section
        expect(@dest_course.reload.active_course_sections).not_to include @section
      end

      it "fails if the section is not crosslisted" do
        other_section = @course.course_sections.create! name: "other section"
        api_call(:delete,
                 "/api/v1/sections/#{other_section.id}/crosslist",
                 @params.merge(id: other_section.to_param),
                 {},
                 {},
                 expected_status: 400)
      end

      it "fails if the section is deleted" do
        @section.destroy
        api_call(:delete,
                 "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(id: @section.to_param),
                 {},
                 {},
                 expected_status: 404)
      end

      it "un-deletes the original course" do
        @course.destroy
        api_call(:delete,
                 "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(id: @section.to_param))
        expect(@course.reload).to be_claimed
      end

      it "fails if the crosslisted course is deleted" do
        @dest_course.destroy
        api_call(:delete,
                 "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(id: @section.to_param),
                 {},
                 {},
                 expected_status: 404)
      end
    end

    context "as teacher" do
      before do
        course_with_teacher_logged_in(course: @course)
      end

      it "disallows un-crosslisting" do
        api_call(:delete,
                 "/api/v1/sections/#{@section.id}/crosslist",
                 @params.merge(id: @section.to_param),
                 {},
                 {},
                 expected_status: 401)
      end
    end
  end
end
