# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

RSpec.describe LatePolicyController do
  let(:valid_attributes) do
    {
      missing_submission_deduction_enabled: true,
      missing_submission_deduction: "1",
      late_submission_deduction_enabled: true,
      late_submission_deduction: "2",
      late_submission_interval: "hour",
      late_submission_minimum_percent_enabled: true,
      late_submission_minimum_percent: "3"
    }
  end

  let(:expected_attributes) do
    {
      "missing_submission_deduction_enabled" => true,
      "missing_submission_deduction" => 1.0,
      "late_submission_deduction_enabled" => true,
      "late_submission_deduction" => 2.0,
      "late_submission_interval" => "hour",
      "late_submission_minimum_percent_enabled" => true,
      "late_submission_minimum_percent" => 3.0
    }
  end

  let(:invalid_attributes) do
    {
      missing_submission_deduction_enabled: true,
      missing_submission_deduction: "-20",
      late_submission_deduction_enabled: true,
      late_submission_deduction: "-20",
      late_submission_interval: "millenia",
      late_submission_minimum_percent_enabled: true,
      late_submission_minimum_percent: "-20"
    }
  end

  let(:new_attributes) do
    {
      missing_submission_deduction_enabled: false,
      missing_submission_deduction: "1.5",
      late_submission_deduction_enabled: false,
      late_submission_deduction: "3",
      late_submission_interval: "day",
      late_submission_minimum_percent_enabled: false,
      late_submission_minimum_percent: "4.74"
    }
  end

  let(:updated_attributes) do
    {
      "missing_submission_deduction_enabled" => false,
      "missing_submission_deduction" => 1.5,
      "late_submission_deduction_enabled" => false,
      "late_submission_deduction" => 3,
      "late_submission_interval" => "day",
      "late_submission_minimum_percent_enabled" => false,
      "late_submission_minimum_percent" => 4.74
    }
  end

  let(:course) { Course.create! }

  before do
    request.accept = "application/json"
    course_with_teacher_logged_in(course:)
  end

  describe "GET #show" do
    context "given a valid late_policy" do
      let!(:late_policy) { course.create_late_policy! valid_attributes }

      before do
        get :show, params: { id: course.to_param }
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(json_parse["late_policy"]).to eql expected_attributes.merge("id" => late_policy.id.to_s) }
    end

    context "given an unauthorized user" do
      let(:user) { User.create! }

      before do
        user_session(user)
        get :show, params: { id: course.to_param }
      end

      it { expect(response).to have_http_status(:unauthorized) }

      it do
        expect(json_parse).to eql(
          "status" => "unauthorized",
          "errors" => [{ "message" => "user not authorized to perform that action" }]
        )
      end
    end

    context "given no late_policy" do
      before do
        get :show, params: { id: course.to_param }
      end

      it { expect(response).to have_http_status(:not_found) }
      it { expect(json_parse).to include("errors" => [{ "message" => "The specified resource does not exist." }]) }
    end
  end

  describe "POST #create" do
    it "creates a new LatePolicy" do
      expect { post :create, params: { id: course.to_param, late_policy: valid_attributes } }.to change(LatePolicy, :count).by(1)
    end

    context "with valid params" do
      before do
        post :create, params: { id: course.to_param, late_policy: valid_attributes }
      end

      it { expect(response).to have_http_status(:created) }
      it { expect(json_parse["late_policy"]).to eql expected_attributes.merge("id" => course.late_policy.id.to_s) }
    end

    context "with invalid params" do
      before do
        post :create, params: { id: course.to_param, late_policy: invalid_attributes }
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
      it { expect(json_parse).to have_key "errors" }
    end

    context "given an unauthorized user" do
      let(:user) { User.create! }

      before do
        user_session(user)
        post :create, params: { id: course.to_param, late_policy: valid_attributes }
      end

      it { expect(response).to have_http_status(:unauthorized) }

      it do
        expect(json_parse).to eql(
          "status" => "unauthorized",
          "errors" => [{ "message" => "user not authorized to perform that action" }]
        )
      end
    end

    context "given an existing late policy associated with the course" do
      let!(:existing_late_policy) { course.create_late_policy! valid_attributes }

      before do
        post :create, params: { id: course.to_param, late_policy: new_attributes }
      end

      it { expect(response).to have_http_status(:bad_request) }

      it do
        expect(json_parse).to eql(
          "status" => "bad_request",
          "errors" => [{ "message" => "only one late policy per course is allowed" }]
        )
      end

      it "does not delete the existing policy" do
        post :create, params: { id: course.to_param, late_policy: new_attributes }
        expect(existing_late_policy.reload).to be_persisted
      end
    end
  end

  describe "PATCH #update" do
    context "given an existing late policy" do
      before do
        course.create_late_policy! valid_attributes
      end

      context "with valid params" do
        before do
          patch :update, params: { id: course.to_param, late_policy: new_attributes }
        end

        it { expect(response).to have_http_status(:no_content) }
        it { expect(response.body).to be_empty }
        it { expect(course.late_policy.reload).to have_attributes updated_attributes }
      end

      context "with invalid params" do
        before do
          patch :update, params: { id: course.to_param, late_policy: invalid_attributes }
        end

        it { expect(response).to have_http_status(:unprocessable_entity) }
        it { expect(json_parse).to have_key "errors" }
      end

      context "given an unauthorized user" do
        let(:user) { User.create! }

        before do
          user_session(user)
          patch :update, params: { id: course.to_param, late_policy: new_attributes }
        end

        it { expect(response).to have_http_status(:unauthorized) }

        it do
          expect(json_parse).to eql(
            "status" => "unauthorized",
            "errors" => [{ "message" => "user not authorized to perform that action" }]
          )
        end
      end
    end

    context "given no existing late policy" do
      before do
        patch :update, params: { id: course.to_param, late_policy: new_attributes }
      end

      it { expect(response).to have_http_status(:not_found) }
      it { expect(json_parse).to include("errors" => [{ "message" => "The specified resource does not exist." }]) }
    end
  end
end
