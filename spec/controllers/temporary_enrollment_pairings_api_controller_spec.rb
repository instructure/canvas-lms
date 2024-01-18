# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe TemporaryEnrollmentPairingsApiController do
  before :once do
    @account = Account.default
    @admin = account_admin_user(account: @account, active_all: true)
    @account.enable_feature!(:temporary_enrollments)
  end

  before do
    user_session(@admin)
    @temporary_enrollment_pairing = @account.temporary_enrollment_pairings.create!(created_by: @admin)
  end

  describe "GET #index" do
    it "lists temporary enrollment pairings" do
      get :index, params: { account_id: @account.id }

      expect(response).to be_successful
      expect(assigns[:temporary_enrollment_pairings]).to include(@temporary_enrollment_pairing)
    end
  end

  describe "GET #show" do
    it "returns a specified temporary enrollment pairing" do
      get :show, params: { account_id: @account.id, id: @temporary_enrollment_pairing.id }

      expect(response).to be_successful
      expect(assigns[:temporary_enrollment_pairing]).to eq(@temporary_enrollment_pairing)
    end
  end

  describe "GET #new" do
    it "instantiates a temporary enrollment pairing" do
      get :new, params: { account_id: @account.id }

      expect(response).to be_successful
      temporary_enrollment_pairing = assigns[:temporary_enrollment_pairing]
      expect(temporary_enrollment_pairing.id).to be_nil
      expect(temporary_enrollment_pairing.root_account_id).to eq(@account.id)
      expect(temporary_enrollment_pairing.workflow_state).to eq("active")
    end
  end

  describe "POST #create" do
    it "creates a new temporary enrollment pairing" do
      post :create, params: { account_id: @account.id }

      expect(response).to be_successful
      json_response = response.parsed_body
      temporary_enrollment_pairing = json_response["temporary_enrollment_pairing"]
      expect(temporary_enrollment_pairing["id"]).not_to be_nil
      expect(temporary_enrollment_pairing["created_by_id"]).to eq(@admin.id)
    end

    it "creates a new temporary enrollment pairing with an ending enrollment state" do
      post :create, params: { account_id: @account.id, ending_enrollment_state: "completed" }

      expect(response).to be_successful
      json_response = response.parsed_body
      temporary_enrollment_pairing = json_response["temporary_enrollment_pairing"]
      expect(temporary_enrollment_pairing["ending_enrollment_state"]).to eq("completed")
    end

    it "does not set ending enrollment state with an invalid ending enrollment state" do
      post :create, params: { account_id: @account.id, ending_enrollment_state: "invalid" }

      expect(response).to be_successful
      json_response = response.parsed_body
      temporary_enrollment_pairing = json_response["temporary_enrollment_pairing"]
      expect(temporary_enrollment_pairing["ending_enrollment_state"]).to eq("deleted")
    end

    it "defaults to deleted ending enrollment state if no ending enrollment state is given" do
      post :create, params: { account_id: @account.id }

      expect(response).to be_successful
      json_response = response.parsed_body
      temporary_enrollment_pairing = json_response["temporary_enrollment_pairing"]
      expect(temporary_enrollment_pairing["ending_enrollment_state"]).to eq("deleted")
    end
  end

  describe "DELETE #destroy" do
    it "deletes a temporary enrollment pairing" do
      delete :destroy, params: { account_id: @account.id, id: @temporary_enrollment_pairing.id }

      expect(response).to be_successful
      expect(@temporary_enrollment_pairing.reload).to be_deleted
      expect(@temporary_enrollment_pairing["deleted_by_id"]).to eq(@admin.id)
    end
  end
end
