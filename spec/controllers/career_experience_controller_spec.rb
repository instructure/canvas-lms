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

describe CareerExperienceController do
  before :once do
    course_with_teacher(active_all: true)
    account_admin_user(account: Account.default, user: @teacher)
  end

  before do
    user_session(@teacher)
  end

  describe "experience_summary" do
    it "returns experience summary for the current user and context" do
      allow_any_instance_of(CanvasCareer::ExperienceResolver).to receive(:resolve).and_return(CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER)
      allow_any_instance_of(CanvasCareer::ExperienceResolver).to receive(:available_apps).and_return([CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER, CanvasCareer::Constants::App::ACADEMIC])

      get :experience_summary, params: { asset_string: @course.asset_string }, format: :json

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["current_app"]).to eq CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER
      expect(json["available_apps"]).to include(CanvasCareer::Constants::App::CAREER_LEARNING_PROVIDER, CanvasCareer::Constants::App::ACADEMIC)
    end
  end

  describe "switch_experience" do
    it "updates the user's preferred experience" do
      preference_manager = instance_double(CanvasCareer::UserPreferenceManager)
      allow(CanvasCareer::UserPreferenceManager).to receive(:new).and_return(preference_manager)
      expect(preference_manager).to receive(:save_preferred_experience)

      post :switch_experience, params: { experience: CanvasCareer::Constants::Experience::CAREER }, format: :json

      expect(response).to be_successful
      expect(json_parse(response.body)["experience"]).to eq CanvasCareer::Constants::Experience::CAREER
    end

    it "returns bad request for invalid experience" do
      post :switch_experience, params: { experience: "invalid" }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_parse(response.body)["error"]).to eq "invalid_experience"
    end
  end

  describe "switch_role" do
    it "updates the user's preferred role" do
      preference_manager = instance_double(CanvasCareer::UserPreferenceManager)
      allow(CanvasCareer::UserPreferenceManager).to receive(:new).and_return(preference_manager)
      expect(preference_manager).to receive(:save_preferred_role)

      post :switch_role, params: { role: CanvasCareer::Constants::Role::LEARNER }, format: :json

      expect(response).to be_successful
      expect(json_parse(response.body)["role"]).to eq CanvasCareer::Constants::Role::LEARNER
    end

    it "returns bad request for invalid role" do
      post :switch_role, params: { role: "invalid" }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(json_parse(response.body)["error"]).to eq "invalid_role"
    end
  end

  describe "enabled" do
    it "returns true when institution has career enabled in subaccounts" do
      allow(CanvasCareer::ExperienceResolver).to receive(:career_affiliated_institution?).and_return(true)

      get :enabled, format: :json
      expect(response).to be_successful

      json = json_parse(response.body)
      expect(json["enabled"]).to be true
    end

    it "returns false when institution does not have career enabled" do
      allow(CanvasCareer::ExperienceResolver).to receive(:career_affiliated_institution?).and_return(false)

      get :enabled, format: :json
      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["enabled"]).to be false
    end
  end
end
