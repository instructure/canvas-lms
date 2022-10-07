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

  before do
    Account.site_admin.enable_feature!(:course_paces_redesign)
    user_session(teacher)
  end

  describe "index" do
    context "when the course type is specified" do
      it "returns an empty array" do
        get api_v1_pace_contexts_path(course.id), params: { type: "course", format: :json }
        expect(response.status).to eq 200
        json = JSON.parse(response.body)
        expect(json["pace_contexts"]).to match_array([])
      end
    end

    context "when the section type is specified" do
      it "returns an empty array" do
        get api_v1_pace_contexts_path(course.id), params: { type: "section", format: :json }
        expect(response.status).to eq 200
        json = JSON.parse(response.body)
        expect(json["pace_contexts"]).to match_array([])
      end
    end

    context "when the student_enrollment type is specified" do
      it "returns an empty array" do
        get api_v1_pace_contexts_path(course.id), params: { type: "student_enrollment", format: :json }
        expect(response.status).to eq 200
        json = JSON.parse(response.body)
        expect(json["pace_contexts"]).to match_array([])
      end
    end

    context "when an invalid type is specified" do
      it "returns a 400" do
        get api_v1_pace_contexts_path(course.id), params: { type: "foobar", format: :json }
        expect(response.status).to eq 400
      end
    end

    context "when no type is specified" do
      it "returns a 400" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response.status).to eq 400
      end
    end

    context "when the user does not have permission to manage the course" do
      let(:teacher) { user_model }

      it "returns a 401" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response.status).to eq 401
      end
    end

    context "when the course_paces_redesign flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:course_paces_redesign)
      end

      it "returns a 404" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response.status).to eq 404
      end
    end

    context "when the specified course does not exist" do
      it "returns a 404" do
        get api_v1_pace_contexts_path(Course.maximum(:id).next), params: { format: :json }
        expect(response.status).to eq 404
      end
    end

    context "when the specified course does not have pacing enabled" do
      let(:course) { teacher_enrollment.course }

      it "returns a 404" do
        get api_v1_pace_contexts_path(course.id), params: { format: :json }
        expect(response.status).to eq 404
      end
    end
  end
end
