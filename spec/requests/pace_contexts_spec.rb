# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../spec_helper"
require_relative "../support/request_helper"

describe "Pace Contexts API" do
  let(:teacher_enrollment) { course_with_teacher(active_all: true) }
  let(:course) do
    course = teacher_enrollment.course
    course.enable_course_paces = true
    course.save!
    course
  end
  let(:teacher) { teacher_enrollment.user }
  let!(:default_pace) { course_pace_model(course:) }

  before do
    Account.site_admin.enable_feature!(:course_paces_redesign)
    user_session(teacher)
  end

  describe "index" do
    context "when the course type is specified" do
      it "returns an array containing only the course" do
        get api_v1_pace_contexts_path(course.id), params: { type: "course", format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace_contexts"].length).to eq 1

        course_json = json["pace_contexts"][0]
        expect(course_json["name"]).to eq course.name
        expect(course_json["type"]).to eq "Course"
        expect(course_json["item_id"]).to eq course.id
        expect(course_json["associated_section_count"]).to eq 1
        expect(course_json["associated_student_count"]).to eq 0

        applied_pace_json = course_json["applied_pace"]
        expect(applied_pace_json["name"]).to eq course.name
        expect(applied_pace_json["type"]).to eq "Course"
        expect(applied_pace_json["duration"]).to eq 1
        expect(Time.parse(applied_pace_json["last_modified"])).to be_within(1.second).of(default_pace.published_at)
      end

      context "when the course does not have a default pace" do
        before { default_pace.destroy! }

        it "returns nil for the applied_pace" do
          get api_v1_pace_contexts_path(course.id), params: { type: "course", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"][0]["applied_pace"]).to be_nil
        end
      end

      it "successfully calls the pace_context api when granular perms on" do
        Account.root_accounts.first.enable_feature!(:granular_permissions_manage_course_content)
        get api_v1_pace_contexts_path(course.id), params: { type: "course", format: :json }
        expect(response).to have_http_status :ok
      end
    end

    context "when the section type is specified" do
      let!(:section_one) { add_section("Section One", course:) }

      it "returns an array containing the sections" do
        get api_v1_pace_contexts_path(course.id), params: { type: "section", format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        course.course_sections.each do |section|
          context_json = json["pace_contexts"].detect { |pc| pc["item_id"] == section.id }
          expect(context_json["name"]).to eq section.name
          expect(context_json["applied_pace"]["type"]).to eq "Course"
        end
      end

      it "paginates results" do
        get api_v1_pace_contexts_path(course.id), params: { type: "section", per_page: 1, format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace_contexts"].count).to eq 1
        expect(json["pace_contexts"][0]["item_id"]).to eq course.default_section.id

        get api_v1_pace_contexts_path(course.id), params: { type: "section", per_page: 1, page: 2, format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace_contexts"].count).to eq 1
        expect(json["pace_contexts"][0]["item_id"]).to eq section_one.id
      end

      context "when a section has its own pace" do
        before { section_pace_model(section: section_one) }

        it "specifies the correct applied_pace" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          course.course_sections.each do |section|
            context_json = json["pace_contexts"].detect { |pc| pc["item_id"] == section.id }
            expected_pace_type = (section.course_paces.count > 0) ? "Section" : "Course"
            expect(context_json["applied_pace"]["type"]).to eq expected_pace_type
          end
        end
      end

      context "when the default pace doesn't exist" do
        before { default_pace.destroy! }

        it "returns nil for the applied_pace" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("applied_pace")).to match_array [nil, nil]
        end
      end
    end

    context "when the student_enrollment type is specified" do
      let(:student) { user_model(name: "Foo Bar") }
      let(:student_two) { user_model(name: "Bar Foo") }
      let!(:enrollment) { course.enroll_student(student, enrollment_state: "active") }
      let!(:enrollment_two) { course.enroll_student(student_two, enrollment_state: "active") }

      it "returns an array containing the student enrollments" do
        get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        course.student_enrollments.each do |se|
          context_json = json["pace_contexts"].detect { |pc| pc["item_id"] == se.id }
          expect(context_json["name"]).to eq se.user.name
          expect(context_json["applied_pace"]["type"]).to eq "Course"
        end
      end

      it "paginates results" do
        get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", per_page: 1, format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace_contexts"].count).to eq 1
        expect(json["pace_contexts"][0]["item_id"]).to eq enrollment.id

        get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", per_page: 1, page: 2, format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace_contexts"].count).to eq 1
        expect(json["pace_contexts"][0]["item_id"]).to eq enrollment_two.id
      end

      context "when students have multiple enrollments in the same course" do
        let(:section_one) { add_section("Section One", course:) }
        let!(:enrollment_two) { course.enroll_student(student_two, allow_multiple_enrollments: true, section: section_one, enrollment_state: "active") }

        before do
          Timecop.freeze(2.weeks.ago) do
            course.enroll_student(student_two, enrollment_state: "active")
            course.enroll_student(student, allow_multiple_enrollments: true, section: section_one, enrollment_state: "active")
          end
        end

        it "returns only the newest enrollment for each student" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].length).to eq 2
          [enrollment, enrollment_two].each do |e|
            pace_context = json["pace_contexts"].detect { |pc| pc["item_id"] == e.id }
            expect(pace_context["name"]).to eq e.user.name
          end
        end
      end

      context "when a the student enrollments have more granular paces" do
        let(:section) { add_section("Section One", course:) }
        let!(:enrollment_two) { multiple_student_enrollment(student_two, section, course:) }

        before do
          student_enrollment_pace_model(student_enrollment: enrollment)
          section_pace_model(section:)
        end

        it "specifies the correct applied_pace" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          context_json = json["pace_contexts"].detect { |pc| pc["item_id"] == enrollment.id }
          expect(context_json["applied_pace"]["type"]).to eq "StudentEnrollment"

          context_json = json["pace_contexts"].detect { |pc| pc["item_id"] == enrollment_two.id }
          expect(context_json["applied_pace"]["type"]).to eq "Section"
        end
      end

      context "when the default pace doesn't exist" do
        before { default_pace.destroy! }

        it "returns nil for the applied_pace" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("applied_pace")).to match_array [nil, nil]
        end
      end
    end

    context "when an invalid type is specified" do
      it "returns a 400" do
        get api_v1_pace_contexts_path(course.id), params: { type: "foobar", format: :json }
        expect(response).to have_http_status :bad_request
      end
    end

    context "when no type is specified" do
      it "returns a 400" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response).to have_http_status :bad_request
      end
    end

    context "when the user does not have permission to manage the course" do
      let(:teacher) { user_model }

      it "returns a 401" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when the course_paces_redesign flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:course_paces_redesign)
      end

      it "returns a 404" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    context "when the specified course does not exist" do
      it "returns a 404" do
        get api_v1_pace_contexts_path(Course.maximum(:id).next), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    context "when the specified course does not have pacing enabled" do
      let(:course) { teacher_enrollment.course }

      it "returns a 404" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    context "when an order is specified" do
      context "sections" do
        let(:default_section) { course.default_section }
        let!(:section_one) { add_section("Section One", course:) }
        let!(:section_two) { add_section("Section Two", course:) }
        let!(:section_three) { add_section("Section Three", course:) }

        it "orders the results in descending order with desc specified" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", order: "desc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [section_three.id, section_two.id, section_one.id, default_section.id]
        end

        it "orders the results in ascending order with asc specified" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", order: "asc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [default_section.id, section_one.id, section_two.id, section_three.id]
        end

        it "orders the results in ascending order by default" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [default_section.id, section_one.id, section_two.id, section_three.id]
        end
      end

      context "student enrollments" do
        let!(:first_student_enrollment) { course.enroll_student(user_model(name: "Foo Bar"), enrollment_state: "active") }
        let!(:second_student_enrollment) { course.enroll_student(user_model(name: "Bar Foo"), enrollment_state: "active") }

        it "orders the results in descending order with desc specified" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", order: "desc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [second_student_enrollment.id, first_student_enrollment.id]
        end

        it "orders the results in ascending order with asc specified" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", order: "asc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [first_student_enrollment.id, second_student_enrollment.id]
        end

        it "orders the results in ascending order by default" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("item_id")).to eq [first_student_enrollment.id, second_student_enrollment.id]
        end
      end
    end

    context "when a sort is specified" do
      context "sections" do
        before do
          add_section("Section C", course:)
          add_section("Section A", course:)
          add_section("Section B", course:)
        end

        it "sorts by the section name" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", sort: "name", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Section A", "Section B", "Section C", "Unnamed Course"]
        end

        it "sorts by the section name and respects descending order" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", sort: "name", order: "desc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Unnamed Course", "Section C", "Section B", "Section A"]
        end
      end

      context "student enrollments" do
        before do
          student = user_model(name: "Foo Bar", sortable_name: "A, Foo")
          student_two = user_model(name: "Bar Foo", sortable_name: "B, Foo")
          course.enroll_student(student, enrollment_state: "active")
          course.enroll_student(student_two, enrollment_state: "active")
        end

        it "sorts by the sortable user name" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", sort: "name", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Foo Bar", "Bar Foo"]
        end

        it "sorts by the sortable user name and respects descending order" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", sort: "name", order: "desc", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Bar Foo", "Foo Bar"]
        end
      end
    end

    context "when a search_term is specified" do
      context "sections" do
        before do
          add_section("Section A", course:)
          add_section("Section B", course:)
          add_section("Section C", course:)
        end

        it "filters by the section name" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", search_term: "a", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Unnamed Course", "Section A"]
        end
      end

      context "student enrollments" do
        before do
          student = user_model(name: "Student Foo", sortable_name: "A, Foo")
          student_two = user_model(name: "Student Bar", sortable_name: "B, Foo")
          course.enroll_student(student, enrollment_state: "active")
          course.enroll_student(student_two, enrollment_state: "active")
        end

        it "filters by the user name" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", search_term: "bAr", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body
          expect(json["pace_contexts"].pluck("name")).to eq ["Student Bar"]
        end
      end
    end

    context "when contexts are specified" do
      context "sections" do
        before do
          @section_a = add_section("Section A", course:)
          @section_b = add_section("Section B", course:)
          @section_c = add_section("Section C", course:)
        end

        it "filters by context ids" do
          get api_v1_pace_contexts_path(course.id), params: { type: "section", contexts: "[#{@section_a.id}, #{@section_c.id}]", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body

          expect(json["pace_contexts"].count).to eq 2
          expect(json["pace_contexts"].pluck("name")).to eq ["Section A", "Section C"]
        end
      end

      context "student enrollments" do
        before do
          @student_1 = user_model(name: "Student Foo", sortable_name: "A, Foo")
          @student_2 = user_model(name: "Student Bar", sortable_name: "B, Foo")
          @student_3 = user_model(name: "Student Boo", sortable_name: "C, Boo")
          @student_1_enrollment = course.enroll_student(@student_1, enrollment_state: "active")
          @student_2_enrollment = course.enroll_student(@student_2, enrollment_state: "active")
          @student_3_enrollment = course.enroll_student(@student_3, enrollment_state: "active")
        end

        it "filters by context ids" do
          get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", contexts: "[#{@student_1_enrollment.id}, #{@student_3_enrollment.id}]", format: :json }
          expect(response).to have_http_status :ok
          json = response.parsed_body

          expect(json["pace_contexts"].count).to eq 2
          expect(json["pace_contexts"].pluck("name")).to eq ["Student Foo", "Student Boo"]
        end
      end
    end
  end
end
