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

describe "Section Paces API" do
  let(:teacher_enrollment) { course_with_teacher(active_all: true) }
  let(:course) { teacher_enrollment.course }
  let(:teacher) { teacher_enrollment.user }
  let(:section) { add_section("Section One", course:) }
  let(:section_two) { add_section("Section Two", course:) }
  let(:section_three) { add_section("Section Three", course:) }
  let(:unrelated_section) { add_section("Section Three", course: course_factory) }

  before do
    Account.site_admin.enable_feature!(:course_paces_redesign)
    2.times { multiple_student_enrollment(user_model, section_two, course:) }
    course.enroll_student(@user = user_factory, enrollment_state: "active")
    user_session(teacher)
  end

  def assert_grant_check
    user_session(@user)
    yield
    expect(response).to have_http_status :unauthorized
  end

  describe "show" do
    it "returns the pace for the requested section" do
      section_pace = section_pace_model(section:)
      Progress.create!(context: section_pace, tag: "course_pace_publish")
      get api_v1_section_pace_path(course, section), params: { format: :json }
      expect(response).to have_http_status :ok
      json = response.parsed_body
      expect(json["pace"]["id"]).to eq section_pace.id
    end

    context "the section does not have a pace, but the course does" do
      before { course_pace_model(course:, workflow_state: "published") }

      it "falls back to the course pace" do
        get api_v1_section_pace_path(course, section), params: { format: :json }
        expect(response).to have_http_status :ok
        json = response.parsed_body
        expect(json["pace"]["id"]).to be_nil
        expect(json["pace"]["workflow_state"]).to eq "unpublished"
      end
    end

    context "the section and course do not have paces" do
      it "returns a 404" do
        get api_v1_section_pace_path(course, section), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    it "returns a 404 if the section and course are unrelated" do
      get api_v1_section_pace_path(course.id, unrelated_section.id), params: { format: :json }
      expect(response).to have_http_status :not_found
    end

    it "returns a 401 if the user lacks permission" do
      assert_grant_check { get api_v1_section_pace_path(course.id, section.id), params: { format: :json } }
    end
  end

  describe "create" do
    it "creates a pace for the specified section" do
      expect do
        post api_v1_new_section_pace_path(course, section), params: { format: :json }
      end.to change {
        section.course_paces.reload.count
      }.by(1)
       .and change { Progress.count }.by(1)
      expect(Progress.last.queued?).to be_truthy
      expect(response).to have_http_status :created
      json = response.parsed_body
      expect(json["pace"]["section"]["name"]).to eq section.name
      expect(json["progress"]["context_id"]).to eq(CoursePace.last.id)
      expect(json["progress"]["tag"]).to eq("course_pace_publish")
    end

    it "returns a 404 if the section and course are unrelated" do
      post api_v1_new_section_pace_path(course, unrelated_section), params: { format: :json }
      expect(response).to have_http_status :not_found
    end

    it "returns a 401 if the user lacks permission" do
      assert_grant_check { post api_v1_new_section_pace_path(course, section), params: { format: :json } }
    end

    context "when the section already has a pace" do
      let!(:section_pace) { section_pace_model(section:) }

      it "returns the existing pace" do
        expect do
          post api_v1_new_section_pace_path(course, section), params: { format: :json }
        end.to not_change {
          section.course_paces.reload.count
        }
        expect(response).to have_http_status :created
        json = response.parsed_body
        expect(json["pace"]["id"]).to eq section_pace.id
        expect(json["progress"]["context_id"]).to eq(CoursePace.last.id)
        expect(json["progress"]["tag"]).to eq("course_pace_publish")
      end
    end
  end

  describe "update" do
    let!(:pace) { section_pace_model(section:) }

    it "updates the pace" do
      expect do
        patch api_v1_patch_section_pace_path(course, section), params: {
          format: :json,
          pace: {
            exclude_weekends: false
          }
        }
      end.to change { pace.reload.exclude_weekends }
        .to(false)
        .and change { Progress.count }.by(1)
      expect(Progress.last.queued?).to be_truthy
      expect(response).to have_http_status :ok
    end

    it "returns a 401 if the user lacks permission" do
      assert_grant_check { patch api_v1_patch_section_pace_path(course, section), params: { format: :json, pace: {} } }
    end

    it "returns a 404 if the section and course are unrelated" do
      patch api_v1_patch_section_pace_path(course, unrelated_section), params: { format: :json, pace: {} }
      expect(response).to have_http_status :not_found
    end

    it "handles invalid update parameters" do
      allow_any_instance_of(CoursePace).to receive(:update).and_return(false)
      patch api_v1_patch_section_pace_path(course, section), params: {
        format: :json,
        pace: {
          exclude_weekends: "foobar"
        }
      }
      expect(response).to have_http_status :unprocessable_entity
    end
  end

  describe "delete" do
    it "marks the pace as deleted" do
      pace = section_pace_model(section:)

      expect do
        delete api_v1_delete_section_pace_path(course, section), params: { format: :json }
      end.to change {
        pace.reload.workflow_state
      }.from("active").to("deleted")
      expect(response).to have_http_status :no_content
    end

    it "returns a 401 if the user lacks permission" do
      assert_grant_check { delete api_v1_delete_section_pace_path(course, section), params: { format: :json } }
    end

    it "returns a 404 if the section and course are unrelated" do
      delete api_v1_delete_section_pace_path(course, unrelated_section), params: { format: :json }
      expect(response).to have_http_status :not_found
    end

    it "returns 404 if the section does not have a pace" do
      delete api_v1_delete_section_pace_path(course, section), params: { format: :json }
      expect(response).to have_http_status :not_found
    end
  end

  context "course_paces_redesign flag is disabled" do
    before do
      Account.site_admin.disable_feature!(:course_paces_redesign)
    end

    describe "show" do
      let(:section_pace) { section_pace_model(section:) }
      let(:course_pace) { course_pace_model(course:) }

      it "returns 404" do
        get api_v1_section_pace_path(course.id, section_pace.id), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    describe "create" do
      it "returns 404" do
        post api_v1_new_section_pace_path(course, section), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end

    describe "update" do
      before { section_pace_model(section:) }

      it "returns 404" do
        patch api_v1_patch_section_pace_path(course, section), params: {
          format: :json,
          pace: {
            exclude_weekends: false
          }
        }
        expect(response).to have_http_status :not_found
      end
    end

    describe "delete" do
      it "returns 404" do
        pace = section_pace_model(section:)
        delete api_v1_delete_section_pace_path(course, section, pace), params: { format: :json }
        expect(response).to have_http_status :not_found
      end
    end
  end
end
