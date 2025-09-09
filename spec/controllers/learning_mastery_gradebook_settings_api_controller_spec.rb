# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../feature_flag_helper"

RSpec.describe LearningMasteryGradebookSettingsApiController do
  include FeatureFlagHelper

  let(:teacher) { course_with_teacher(active_all: true).user }

  before do
    user_session(teacher)
    request.accept = "application/json"
    mock_feature_flag(:outcome_gradebook, true)
  end

  describe "GET show" do
    context "with existing settings" do
      let(:existing_settings) do
        {
          "secondary_info_display" => "points",
          "show_students_with_no_results" => true,
          "show_student_avatars" => false
        }
      end

      before do
        teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, existing_settings)
      end

      it "returns the current settings" do
        get :show, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(json_parse).to include(
          "learning_mastery_gradebook_settings" => existing_settings
        )
      end
    end

    context "with no existing settings" do
      it "returns empty settings" do
        get :show, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(json_parse).to include(
          "learning_mastery_gradebook_settings" => {}
        )
      end
    end

    context "without proper authorization" do
      let(:student) { student_in_course(active_all: true).user }

      before { user_session(student) }

      it "returns forbidden" do
        get :show, params: { course_id: @course.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT update" do
    context "with valid params" do
      let(:learning_mastery_gradebook_settings) do
        {
          "secondary_info_display" => "percentage",
          "show_students_with_no_results" => true,
          "show_student_avatars" => false
        }
      end

      let(:valid_params) do
        {
          course_id: @course.id,
          learning_mastery_gradebook_settings:
        }
      end

      it "updates and returns the settings" do
        put :update, params: valid_params

        expect(response).to be_successful
        expect(json_parse).to include(
          "learning_mastery_gradebook_settings" => learning_mastery_gradebook_settings.transform_values(&:to_s)
        )
      end

      it "persists the settings in user preferences" do
        put :update, params: valid_params

        saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
        expect(saved_settings).to eq(learning_mastery_gradebook_settings.transform_values(&:to_s))
      end

      it "merges with existing settings" do
        existing_settings = { "existing_key" => "existing_value" }
        teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, existing_settings)

        put :update, params: valid_params

        expected_settings = existing_settings.merge(learning_mastery_gradebook_settings)
        expect(json_parse["learning_mastery_gradebook_settings"]).to eq(expected_settings.transform_values(&:to_s))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          course_id: @course.id
        }
      end

      it "returns bad request when required params are missing" do
        put :update, params: invalid_params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without proper authorization" do
      let(:student) { student_in_course(active_all: true).user }
      let(:valid_params) do
        {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "secondary_info_display" => "percentage"
          }
        }
      end

      before { user_session(student) }

      it "returns forbidden" do
        put :update, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "for concluded courses" do
      let(:valid_params) do
        {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "secondary_info_display" => "percentage"
          }
        }
      end

      it "allows updates for courses in concluded enrollment terms" do
        @course.update!(enrollment_term: teacher.account.enrollment_terms.create!(start_at: 2.months.ago, end_at: 1.month.ago))

        put :update, params: valid_params

        expect(response).to be_successful
      end

      it "allows updates for courses with concluded workflow state" do
        @course.update!(workflow_state: "concluded")

        put :update, params: valid_params

        expect(response).to be_successful
      end
    end

    context "with only permitted parameters" do
      let(:params_with_unpermitted) do
        {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "secondary_info_display" => "percentage",
            "show_students_with_no_results" => true,
            "show_student_avatars" => false,
            "unpermitted_param" => "should_be_filtered"
          }
        }
      end

      it "filters out unpermitted parameters" do
        put :update, params: params_with_unpermitted

        expect(response).to be_successful
        saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
        expect(saved_settings).not_to have_key("unpermitted_param")
        expect(saved_settings).to include(
          "secondary_info_display" => "percentage",
          "show_students_with_no_results" => "true",
          "show_student_avatars" => "false"
        )
      end
    end
  end

  describe "permissions" do
    let(:account_admin) { account_admin_user(account: @course.account) }
    let(:ta) { ta_in_course(course: @course, active_all: true).user }

    it "allows access to teachers without manage_grades but without view_all_grades permission" do
      @course.root_account.role_overrides.create!(permission: "view_all_grades", role: teacher_role, enabled: false)
      @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: true)
      user_session(teacher)
      get :show, params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "allows access to teachers with view_all_grades but without manage_grades permission" do
      @course.root_account.role_overrides.create!(permission: "view_all_grades", role: teacher_role, enabled: true)
      @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
      user_session(teacher)
      get :show, params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "denies access to teachers without manage_grades and view_all_grades permissions" do
      @course.root_account.role_overrides.create!(permission: "view_all_grades", role: teacher_role, enabled: false)
      @course.root_account.role_overrides.create!(permission: "manage_grades", role: teacher_role, enabled: false)
      user_session(teacher)
      get :show, params: { course_id: @course.id }
      expect(response).to have_http_status(:forbidden)
    end

    context "without outcome_gradebook permission" do
      before do
        mock_feature_flag(:outcome_gradebook, false)
      end

      it "returns no_content even for teachers" do
        get :show, params: { course_id: @course.id }
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
