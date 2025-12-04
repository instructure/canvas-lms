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
          "secondary_info_display" => "sis_id",
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
            "secondary_info_display" => "sis_id"
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
            "secondary_info_display" => "sis_id"
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
            "secondary_info_display" => "sis_id",
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
          "secondary_info_display" => "sis_id",
          "show_students_with_no_results" => "true",
          "show_student_avatars" => "false"
        )
      end
    end

    context "with name_display_format parameter" do
      it "persists name_display_format when set to first_last" do
        params = {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "name_display_format" => "first_last"
          }
        }

        put(:update, params:)

        expect(response).to be_successful
        saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
        expect(saved_settings).to include("name_display_format" => "first_last")
      end

      it "persists name_display_format when set to last_first" do
        params = {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "name_display_format" => "last_first"
          }
        }

        put(:update, params:)

        expect(response).to be_successful
        saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
        expect(saved_settings).to include("name_display_format" => "last_first")
      end

      it "returns the saved name_display_format on subsequent GET requests" do
        teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, { "name_display_format" => "last_first" })

        get :show, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(json_parse["learning_mastery_gradebook_settings"]).to include("name_display_format" => "last_first")
      end
    end

    context "with students_per_page parameter" do
      it "persists students_per_page when set to 30" do
        params = {
          course_id: @course.id,
          learning_mastery_gradebook_settings: {
            "students_per_page" => 30
          }
        }

        put(:update, params:)

        expect(response).to be_successful
        saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
        expect(saved_settings).to include("students_per_page" => "30")
      end

      it "returns the saved students_per_page on subsequent GET requests" do
        teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, { "students_per_page" => 50 })

        get :show, params: { course_id: @course.id }

        expect(response).to be_successful
        expect(json_parse["learning_mastery_gradebook_settings"]).to include("students_per_page" => 50)
      end
    end

    context "with parameter validation" do
      describe "secondary_info_display validation" do
        it "accepts 'none' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "none" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["secondary_info_display"]).to eq("none")
        end

        it "accepts 'sis_id' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "sis_id" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["secondary_info_display"]).to eq("sis_id")
        end

        it "accepts 'integration_id' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "integration_id" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["secondary_info_display"]).to eq("integration_id")
        end

        it "accepts 'login_id' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "login_id" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["secondary_info_display"]).to eq("login_id")
        end

        it "rejects invalid values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "invalid_value" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid secondary_info_display.*Valid values are/))
        end

        it "rejects 'percentage' (previously allowed)" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "percentage" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid secondary_info_display.*Valid values are/))
        end

        it "rejects 'points' (previously allowed)" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "points" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid secondary_info_display.*Valid values are/))
        end

        it "rejects empty string" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "secondary_info_display" => "" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid secondary_info_display.*Valid values are/))
        end
      end

      describe "show_students_with_no_results validation" do
        it "accepts true as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => true }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_students_with_no_results"]).to eq("true")
        end

        it "accepts false as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => false }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_students_with_no_results"]).to eq("false")
        end

        it "accepts 'true' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => "true" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_students_with_no_results"]).to eq("true")
        end

        it "accepts 'false' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => "false" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_students_with_no_results"]).to eq("false")
        end

        it "rejects non-boolean values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => "invalid" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid show_students_with_no_results.*Valid values are/))
        end

        it "rejects numeric values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_students_with_no_results" => 1 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid show_students_with_no_results.*Valid values are/))
        end
      end

      describe "show_student_avatars validation" do
        it "accepts true as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => true }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_student_avatars"]).to eq("true")
        end

        it "accepts false as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => false }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_student_avatars"]).to eq("false")
        end

        it "accepts 'true' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => "true" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_student_avatars"]).to eq("true")
        end

        it "accepts 'false' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => "false" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["show_student_avatars"]).to eq("false")
        end

        it "rejects non-boolean values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => "invalid" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid show_student_avatars.*Valid values are/))
        end

        it "rejects numeric values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "show_student_avatars" => 0 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid show_student_avatars.*Valid values are/))
        end
      end

      describe "name_display_format validation" do
        it "accepts 'first_last' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "name_display_format" => "first_last" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["name_display_format"]).to eq("first_last")
        end

        it "accepts 'last_first' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "name_display_format" => "last_first" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["name_display_format"]).to eq("last_first")
        end

        it "rejects invalid values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "name_display_format" => "invalid_value" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid name_display_format.*Valid values are/))
        end

        it "rejects empty string" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "name_display_format" => "" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid name_display_format.*Valid values are/))
        end

        it "rejects numeric values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "name_display_format" => 123 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid name_display_format.*Valid values are/))
        end
      end

      describe "score_display_format validation" do
        it "accepts 'icon_only' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "score_display_format" => "icon_only" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["score_display_format"]).to eq("icon_only")
        end

        it "accepts 'icon_and_points' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "score_display_format" => "icon_and_points" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["score_display_format"]).to eq("icon_and_points")
        end

        it "accepts 'icon_and_label' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "score_display_format" => "icon_and_label" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["score_display_format"]).to eq("icon_and_label")
        end

        it "rejects invalid values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "score_display_format" => "invalid_value" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid score_display_format.*Valid values are/))
        end

        it "rejects empty string" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "score_display_format" => "" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid score_display_format.*Valid values are/))
        end

        it "returns the saved score_display_format on subsequent GET requests" do
          teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, { "score_display_format" => "icon_and_points" })

          get :show, params: { course_id: @course.id }

          expect(response).to be_successful
          expect(json_parse["learning_mastery_gradebook_settings"]).to include("score_display_format" => "icon_and_points")
        end
      end

      describe "outcome_arrangement validation" do
        it "accepts 'alphabetical' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "outcome_arrangement" => "alphabetical" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["outcome_arrangement"]).to eq("alphabetical")
        end

        it "accepts 'custom' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "outcome_arrangement" => "custom" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["outcome_arrangement"]).to eq("custom")
        end

        it "accepts 'upload_order' as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "outcome_arrangement" => "upload_order" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["outcome_arrangement"]).to eq("upload_order")
        end

        it "rejects invalid values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "outcome_arrangement" => "invalid_value" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid outcome_arrangement.*Valid values are/))
        end

        it "rejects empty string" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "outcome_arrangement" => "" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid outcome_arrangement.*Valid values are/))
        end

        it "returns the saved outcome_arrangement on subsequent GET requests" do
          teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, { "outcome_arrangement" => "custom" })

          get :show, params: { course_id: @course.id }

          expect(response).to be_successful
          expect(json_parse["learning_mastery_gradebook_settings"]).to include("outcome_arrangement" => "custom")
        end
      end

      describe "students_per_page validation" do
        it "accepts 15 as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 15 }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("15")
        end

        it "accepts 30 as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 30 }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("30")
        end

        it "accepts 50 as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 50 }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("50")
        end

        it "accepts 100 as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 100 }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("100")
        end

        it "accepts '15' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => "15" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("15")
        end

        it "accepts '30' string as a valid value" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => "30" }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings["students_per_page"]).to eq("30")
        end

        it "rejects invalid numeric values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 25 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid students_per_page.*Valid values are/))
        end

        it "rejects zero" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => 0 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid students_per_page.*Valid values are/))
        end

        it "rejects negative values" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => -15 }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid students_per_page.*Valid values are/))
        end

        it "rejects non-numeric strings" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: { "students_per_page" => "invalid" }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid students_per_page.*Valid values are/))
        end
      end

      describe "multiple validation errors" do
        it "returns all validation errors when multiple parameters are invalid" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: {
              "secondary_info_display" => "invalid",
              "show_students_with_no_results" => "not_boolean",
              "show_student_avatars" => 123,
              "name_display_format" => "invalid_format",
              "students_per_page" => 25,
              "score_display_format" => "invalid_format",
              "outcome_arrangement" => "invalid_arrangement"
            }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"].length).to eq(7)
          expect(json["errors"]).to include(
            a_string_matching(/Invalid secondary_info_display.*Valid values are/),
            a_string_matching(/Invalid show_students_with_no_results.*Valid values are/),
            a_string_matching(/Invalid show_student_avatars.*Valid values are/),
            a_string_matching(/Invalid name_display_format.*Valid values are/),
            a_string_matching(/Invalid students_per_page.*Valid values are/),
            a_string_matching(/Invalid score_display_format.*Valid values are/),
            a_string_matching(/Invalid outcome_arrangement.*Valid values are/)
          )
        end
      end

      describe "mixed valid and invalid parameters" do
        it "rejects the request if any parameter is invalid" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: {
              "secondary_info_display" => "sis_id",
              "show_students_with_no_results" => "invalid"
            }
          }

          expect(response).to have_http_status(:unprocessable_content)
          json = json_parse
          expect(json["errors"]).to include(a_string_matching(/Invalid show_students_with_no_results.*Valid values are/))
        end

        it "does not save any settings when validation fails" do
          existing_settings = { "existing_key" => "existing_value" }
          teacher.set_preference(:learning_mastery_gradebook_settings, @course.global_id, existing_settings)

          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: {
              "secondary_info_display" => "sis_id",
              "show_students_with_no_results" => "invalid"
            }
          }

          expect(response).to have_http_status(:unprocessable_content)
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings).to eq(existing_settings)
        end
      end

      describe "validation with all parameters valid" do
        it "successfully updates all parameters when all are valid" do
          put :update, params: {
            course_id: @course.id,
            learning_mastery_gradebook_settings: {
              "secondary_info_display" => "login_id",
              "show_students_with_no_results" => true,
              "show_student_avatars" => false,
              "name_display_format" => "last_first",
              "students_per_page" => 50,
              "score_display_format" => "icon_and_label",
              "outcome_arrangement" => "alphabetical"
            }
          }

          expect(response).to be_successful
          saved_settings = teacher.get_preference(:learning_mastery_gradebook_settings, @course.global_id)
          expect(saved_settings).to include(
            "secondary_info_display" => "login_id",
            "show_students_with_no_results" => "true",
            "show_student_avatars" => "false",
            "name_display_format" => "last_first",
            "students_per_page" => "50",
            "score_display_format" => "icon_and_label",
            "outcome_arrangement" => "alphabetical"
          )
        end
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
